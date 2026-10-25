import { buildCode } from '../lib/qr';
import { cleanText, isPositiveInt, isUid } from '../lib/rules';
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
