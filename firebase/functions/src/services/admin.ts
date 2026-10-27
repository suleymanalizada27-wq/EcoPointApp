import { buildCode } from '../lib/qr';
import { cleanText, isPositiveInt, isProActive, isUid } from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import { secureRng } from './context';
import { randomCode } from '../lib/rules';
import { credit, debit, increment, notify } from './wallet';

/** Admin-only (custom claim `admin: true`, enforced in index.ts). */
export async function adminAdjustBalance(
  { store, now }: Deps,
  adminUid: string,
  input: { uid: unknown; delta: unknown; reason: unknown },
): Promise<{ balance: number }> {
  if (typeof input.uid !== 'string' || !isUid(input.uid)) throw Errors.invalid('Invalid uid');
  const delta = input.delta;
  if (typeof delta !== 'number' || !Number.isInteger(delta) || delta === 0 || Math.abs(delta) > 100_000) {
    throw Errors.invalid('Invalid delta');
  }
  const reason = cleanText(input.reason, 80) || 'Admin adjustment';
  if (!(await store.get(`users/${input.uid}`))) throw Errors.notFound('User');

  const balance =
    delta > 0
      ? await credit(store, input.uid, delta, { type: 'other', desc: `🛠 ${reason}` }, now)
      : await debit(store, input.uid, -delta, { type: 'other', desc: `🛠 ${reason}` }, now);
  await store.push('adminLog', { by: adminUid, action: 'adjustBalance', uid: input.uid, delta, reason, ts: now });
  return { balance };
}

export async function adminBroadcast(
  { store, now, push }: Deps,
  adminUid: string,
  input: { title: unknown; body: unknown },
): Promise<{ ok: true }> {
  const title = cleanText(input.title, 80);
  const body = cleanText(input.body, 240);
  if (!title) throw Errors.invalid('Title required');
  await store.push('globalNotifications', { title, body, icon: '📢', ts: now, by: adminUid });
  if (push) await push.toNews({ title, body });
  return { ok: true };
}

/** Marks a BakıKart request done, or rejects it and refunds the EP. */
export async function adminResolveTransport(
  { store, now, push }: Deps,
  adminUid: string,
  input: { requestId: unknown; approve: unknown },
): Promise<{ status: 'completed' | 'rejected' }> {
  if (typeof input.requestId !== 'string' || input.requestId.length > 64) {
    throw Errors.invalid('Invalid request');
  }
  const path = `transportRequests/${input.requestId}`;
  const req = await store.get<any>(path);
  if (!req) throw Errors.notFound('Request');
  const claim = await store.transaction(`${path}/status`, (cur) =>
    cur === 'pending' ? (input.approve === true ? 'completed' : 'rejected') : undefined,
  );
  if (!claim.committed) throw Errors.duplicate('Already resolved');

  if (input.approve === true) {
    await store.update(`users/${req.uid}/purchases/${req.purchaseId}`, { status: 'completed' });
    await notify(store, req.uid, '🚌 BakıKart', 'Top-up completed', now, push);
    await store.push('adminLog', { by: adminUid, action: 'transport-approve', id: input.requestId, ts: now });
    return { status: 'completed' };
  }
  await credit(store, req.uid, req.ep, { type: 'other', desc: '↩ BakıKart refund' }, now);
  await increment(store, `users/${req.uid}/stats/spent`, -req.ep);
  await store.update(`users/${req.uid}/purchases/${req.purchaseId}`, { status: 'refunded' });
  await notify(store, req.uid, '🚌 BakıKart', 'Top-up was rejected; EP refunded', now, push);
  await store.push('adminLog', { by: adminUid, action: 'transport-reject', id: input.requestId, ts: now });
  return { status: 'rejected' };
}

/** Issues a signed single-use bin code (testing / provisioning tool). */
export function issueBinCode(
  secret: string,
  binId: unknown,
  ttlSeconds: unknown,
  nowMs: number,
): { code: string; expiresAt: number } {
  if (typeof binId !== 'string' || !/^[A-Za-z0-9_-]{1,64}$/.test(binId)) {
    throw Errors.invalid('Invalid bin id');
  }
  const ttl = isPositiveInt(ttlSeconds, 10, 7 * 86_400) ? ttlSeconds : 300;
  const exp = Math.floor(nowMs / 1000) + ttl;
  const nonce = randomCode(12, secureRng).toLowerCase();
  return { code: buildCode(secret, binId, nonce, exp), expiresAt: exp };
}

// ───────────────────────── admin console ─────────────────────────

const log = (store: Deps['store'], by: string, action: string, extra: Record<string, unknown>, now: number) =>
  store.push('adminLog', { by, action, ...extra, ts: now });

export async function adminOverview({ store, now }: Deps): Promise<Record<string, number>> {
  const board = (await store.get<Record<string, any>>('leaderboard')) ?? {};
  const users = Object.values(board);
  const devices = (await store.get<Record<string, any>>('devices')) ?? {};
  const transport = (await store.get<Record<string, any>>('transportRequests')) ?? {};
  const errors = (await store.get<Record<string, any>>('errorLogs')) ?? {};
  const pushUsers = (await store.get<Record<string, unknown>>('pushUsers')) ?? {};
  const dayAgo = now - 86_400_000;
  return {
    users: users.length,
    totalEp: users.reduce((s, u) => s + (Number(u?.ep) || 0), 0),
    bins: Object.keys(devices).length,
    pendingTransport: Object.values(transport).filter((r: any) => r?.status === 'pending').length,
    errors24h: Object.values(errors).filter((e: any) => Number(e?.ts) > dayAgo).length,
    pushDevices: Object.keys(pushUsers).length,
  };
}

export async function adminSearchUsers(
  { store }: Deps,
  queryRaw: unknown,
): Promise<{ users: Array<{ uid: string; name: string; ep: number }> }> {
  const q = cleanText(queryRaw, 40);
  if (q.length < 2) return { users: [] };
  const map = (key: string, v: any) => ({ uid: key, name: String(v?.name ?? '—'), ep: Number(v?.ep) || 0 });
  if (isUid(q)) {
    const hit = await store.get<any>(`leaderboard/${q}`);
    return { users: hit ? [map(q, hit)] : [] };
  }
  const rows = await store.queryByChildPrefix('leaderboard', 'nameLower', q.toLowerCase(), 20);
  return { users: rows.map((r) => map(r.key, r.value)) };
}

export async function adminGetUser({ store, now }: Deps, uidRaw: unknown): Promise<Record<string, unknown>> {
  if (typeof uidRaw !== 'string' || !isUid(uidRaw)) throw Errors.invalid('Invalid uid');
  const u = await store.get<any>(`users/${uidRaw}`);
  if (!u) throw Errors.notFound('User');
  return {
    uid: uidRaw,
    name: u.name ?? '—',
    email: u.email ?? '',
    balance: Number(u.balance) || 0,
    createdAt: Number(u.createdAt) || 0,
    earned: Number(u.stats?.earned) || 0,
    spent: Number(u.stats?.spent) || 0,
    sent: Number(u.stats?.sent) || 0,
    referralCount: Number(u.referralCount) || 0,
    isPro: isProActive(u, now),
    proExpiry: Number(u.proExpiry) || 0,
    banned: Boolean(await store.get(`security/banned/${uidRaw}`)),
  };
}

export async function adminSetBan(
  { store, now }: Deps,
  adminUid: string,
  input: { uid: unknown; banned: unknown; reason: unknown },
): Promise<{ banned: boolean }> {
  if (typeof input.uid !== 'string' || !isUid(input.uid)) throw Errors.invalid('Invalid uid');
  if (input.uid === adminUid) throw Errors.invalid('You cannot ban yourself');
  const banned = input.banned === true;
  if (banned) await store.set(`security/banned/${input.uid}`, { ts: now, by: adminUid });
  else await store.remove(`security/banned/${input.uid}`);
  await log(store, adminUid, banned ? 'ban' : 'unban', { uid: input.uid, reason: cleanText(input.reason, 80) }, now);
  return { banned };
}

export async function adminSetPro(
  { store, now }: Deps,
  adminUid: string,
  input: { uid: unknown; days: unknown },
): Promise<{ isPro: boolean; proExpiry: number }> {
  if (typeof input.uid !== 'string' || !isUid(input.uid)) throw Errors.invalid('Invalid uid');
  if (!(await store.get(`users/${input.uid}`))) throw Errors.notFound('User');
  const days = input.days;
  if (typeof days !== 'number' || !Number.isInteger(days) || days < 0 || days > 3650) {
    throw Errors.invalid('Invalid days');
  }
  const out = days === 0 ? { isPro: false, proExpiry: 0 } : { isPro: true, proExpiry: now + days * 86_400_000 };
  await store.update(`users/${input.uid}`, out);
  await log(store, adminUid, 'setPro', { uid: input.uid, days }, now);
  return out;
}

const CATS = ['food', 'tech', 'eco', 'service'];

export async function adminUpsertReward(
  { store, now }: Deps,
  adminUid: string,
  input: Record<string, unknown>,
): Promise<{ id: string }> {
  const id = typeof input.id === 'string' ? input.id : '';
  if (!/^[A-Za-z0-9_-]{1,32}$/.test(id)) throw Errors.invalid('Invalid id');
  if (!isPositiveInt(input.ep, 1, 1_000_000)) throw Errors.invalid('Invalid price');
  const nm = (input.name ?? {}) as Record<string, unknown>;
  const name = {
    az: cleanText(nm.az, 60),
    en: cleanText(nm.en, 60) || cleanText(nm.az, 60),
    ru: cleanText(nm.ru, 60) || cleanText(nm.az, 60),
    tr: cleanText(nm.tr, 60) || cleanText(nm.az, 60),
  };
  if (!name.az) throw Errors.invalid('Name required');
  const cat = CATS.includes(String(input.cat)) ? String(input.cat) : 'service';
  const record: Record<string, unknown> = {
    name,
    brand: cleanText(input.brand, 40),
    ep: input.ep,
    cat,
    icon: cleanText(input.icon, 24),
    kind: 'item',
    active: input.active !== false,
  };
  if (input.stock !== undefined && input.stock !== null && input.stock !== '') {
    if (typeof input.stock !== 'number' || !Number.isInteger(input.stock) || input.stock < 0 || input.stock > 1_000_000) {
      throw Errors.invalid('Invalid stock');
    }
    record.stock = input.stock;
  }
  await store.update(`rewards/${id}`, record);
  await log(store, adminUid, 'upsertReward', { id }, now);
  return { id };
}

export async function adminDeleteReward(
  { store, now }: Deps,
  adminUid: string,
  idRaw: unknown,
): Promise<{ ok: true }> {
  if (typeof idRaw !== 'string' || !/^[A-Za-z0-9_-]{1,32}$/.test(idRaw)) throw Errors.invalid('Invalid id');
  await store.remove(`rewards/${idRaw}`);
  await log(store, adminUid, 'deleteReward', { id: idRaw }, now);
  return { ok: true };
}

/** Creates/updates a bin's public info (never touches its telemetry). */
export async function adminUpsertDevice(
  { store, now }: Deps,
  adminUid: string,
  input: Record<string, unknown>,
): Promise<{ id: string }> {
  const id = typeof input.id === 'string' ? input.id : '';
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(id)) throw Errors.invalid('Invalid bin id');
  const record: Record<string, unknown> = {
    name: cleanText(input.name, 60) || id,
    location: cleanText(input.location, 80),
  };
  const lat = input.lat;
  const lng = input.lng;
  if (lat !== undefined && lat !== null && lat !== '') {
    if (typeof lat !== 'number' || typeof lng !== 'number' || Math.abs(lat) > 90 || Math.abs(lng) > 180) {
      throw Errors.invalid('Invalid coordinates');
    }
    record.lat = lat;
    record.lng = lng;
  }
  await store.update(`devices/${id}`, record);
  await log(store, adminUid, 'upsertDevice', { id }, now);
  return { id };
}

export async function adminListTransport({ store }: Deps): Promise<{ requests: unknown[] }> {
  const all = (await store.get<Record<string, any>>('transportRequests')) ?? {};
  const requests = Object.entries(all)
    .filter(([, r]) => r?.status === 'pending')
    .map(([id, r]) => ({ id, card: r.card, ep: r.ep, netEp: r.netEp, fee: r.fee, uid: r.uid, ts: r.ts }))
    .sort((a, b) => Number(a.ts) - Number(b.ts))
    .slice(0, 50);
  return { requests };
}

const COUPON_RE = /^[A-Z]{3}-[A-Z0-9]{4,12}$/;

export async function adminLookupCoupon({ store }: Deps, codeRaw: unknown): Promise<Record<string, unknown>> {
  const code = typeof codeRaw === 'string' ? codeRaw.trim().toUpperCase() : '';
  if (!COUPON_RE.test(code)) throw Errors.invalid('Invalid coupon code');
  const c = await store.get<any>(`coupons/${code}`);
  if (!c) throw Errors.notFound('Coupon');
  const owner = await store.get<string>(`users/${c.uid}/name`);
  return { code, partnerId: c.partnerId, ep: c.ep, azn: c.azn, status: c.status, ts: c.ts, owner: owner ?? '—' };
}

/** Marks a coupon used exactly once (atomic), e.g. by partner staff. */
export async function adminRedeemCoupon(
  { store, now }: Deps,
  adminUid: string,
  codeRaw: unknown,
): Promise<Record<string, unknown>> {
  const info = await adminLookupCoupon({ store, now }, codeRaw);
  const code = String(info.code);
  const claim = await store.transaction(`coupons/${code}/status`, (cur) =>
    cur === 'issued' ? 'used' : undefined,
  );
  if (!claim.committed) throw Errors.duplicate('Coupon already used');
  const c = await store.get<any>(`coupons/${code}`);
  await store.update(`coupons/${code}`, { usedAt: now, usedBy: adminUid });
  const mine = (await store.get<Record<string, any>>(`users/${c.uid}/coupons`)) ?? {};
  for (const [k, v] of Object.entries(mine)) {
    if (v?.code === code) await store.update(`users/${c.uid}/coupons/${k}`, { status: 'used' });
  }
  await log(store, adminUid, 'redeemCoupon', { code }, now);
  return { ...info, status: 'used' };
}

export async function adminErrorLogs({ store }: Deps): Promise<{ errors: unknown[] }> {
  const all = (await store.get<Record<string, any>>('errorLogs')) ?? {};
  const errors = Object.entries(all)
    .map(([id, e]) => ({ id, ...e }))
    .sort((a, b) => Number(b.ts) - Number(a.ts))
    .slice(0, 50);
  return { errors };
}
