import { CONFIG } from '../lib/config';
import { depositMac, deviceKey, parseCode, verifyDepositMac, verifySignature } from '../lib/qr';
import { dayKey, isProActive, randomCode, scanReward, weightReward } from '../lib/rules';
import { Errors } from '../errors';
import { secureRng, type Deps } from './context';
import { assertNotBanned, credit, increment, rateLimit, reserveDaily } from './wallet';

/** How long a scan stays "open" while the person drops the waste in. */
export const SESSION_TTL_MS = 180_000;
const BIN_ID = /^[A-Za-z0-9_-]{1,64}$/;
const EVENT_ID = /^[A-Za-z0-9_-]{1,64}$/;
const SID = /^[a-z0-9]{16}$/;

export interface SessionInfo {
  sessionId: string;
  binId: string;
  binName: string;
  expiresAt: number;
}

interface Active {
  sid: string;
  uid: string;
  exp: number;
  status: 'open';
}

/**
 * The person scanned the bin's static QR. Nothing is paid here: this only
 * says "uid stands at this bin" for the next SESSION_TTL_MS. The bin's own
 * authenticated deposit message (deviceDeposit) is what pays.
 */
export async function openSession(
  { store, now }: Deps,
  secret: string,
  uid: string,
  payload: unknown,
): Promise<SessionInfo> {
  const code = parseCode(payload);
  if (!code || !verifySignature(secret, code)) throw Errors.invalidQr();
  await assertNotBanned(store, uid);
  const bin = await store.get<any>(`devices/${code.binId}`);
  if (bin === null) throw Errors.invalidQr('Unknown bin');
  if (bin.disabled === true) throw Errors.binDisabled();

  await rateLimit(store, `scan/${uid}`, now, {
    windowMs: 3_600_000,
    max: CONFIG.maxScansPerHour,
    minIntervalMs: CONFIG.minScanIntervalMs,
  });

  const sid = randomCode(16, secureRng).toLowerCase().replace(/[^a-z0-9]/g, 'x');
  const sessionId = sid.padEnd(16, 'x').slice(0, 16);
  let existing: Active | null = null;
  const tx = await store.transaction(`binActive/${code.binId}`, (cur) => {
    const c = cur as Active | null;
    if (c && c.status === 'open' && c.exp > now) {
      existing = c;
      return undefined;
    }
    return { sid: sessionId, uid, exp: now + SESSION_TTL_MS, status: 'open' } satisfies Active;
  });
  const binName = String(bin.name ?? code.binId);
  if (!tx.committed) {
    const e = existing as Active | null;
    if (e && e.uid === uid) return { sessionId: e.sid, binId: code.binId, binName, expiresAt: e.exp };
    throw Errors.binBusy();
  }
  await store.set(`qrSessions/${sessionId}`, {
    uid,
    binId: code.binId,
    status: 'open',
    openedAt: now,
    exp: now + SESSION_TTL_MS,
  });
  return { sessionId, binId: code.binId, binName, expiresAt: now + SESSION_TTL_MS };
}

export interface SessionStatus {
  status: 'open' | 'done' | 'failed' | 'cancelled' | 'expired';
  binId: string;
  expiresAt: number;
  result?: { ep: number; grams: number; balance: number; baseEp: number; multiplier: number };
  reason?: string;
}

/** Polled by the app while it waits for the bin to confirm the deposit. */
export async function sessionStatus(
  { store, now }: Deps,
  uid: string,
  input: { sessionId: unknown },
): Promise<SessionStatus> {
  if (typeof input.sessionId !== 'string' || !SID.test(input.sessionId)) throw Errors.invalid('Invalid session');
  await rateLimit(store, `sessstatus/${uid}`, now, { windowMs: 60_000, max: 90 });
  const s = await store.get<any>(`qrSessions/${input.sessionId}`);
  if (!s || s.uid !== uid) throw Errors.notFound('Session');
  const status: SessionStatus['status'] =
    s.status === 'open' && Number(s.exp) <= now ? 'expired' : (s.status as SessionStatus['status']);
  return { status, binId: s.binId, expiresAt: Number(s.exp), result: s.result, reason: s.reason };
}

export async function cancelSession(
  { store }: Deps,
  uid: string,
  input: { sessionId: unknown },
): Promise<{ ok: true }> {
  if (typeof input.sessionId !== 'string' || !SID.test(input.sessionId)) throw Errors.invalid('Invalid session');
  const s = await store.get<any>(`qrSessions/${input.sessionId}`);
  if (!s || s.uid !== uid) throw Errors.notFound('Session');
  if (s.status === 'open') {
    await store.update(`qrSessions/${input.sessionId}`, { status: 'cancelled' });
    await store.transaction(`binActive/${s.binId}`, (cur) =>
      (cur as Active | null)?.sid === input.sessionId ? null : undefined,
    );
  }
  return { ok: true };
}

export interface DepositResult {
  ep: number;
  grams: number;
  balance: number;
  baseEp: number;
  multiplier: number;
  duplicate?: true;
}

/** Messages from a bin are accepted this far from the server clock. */
const MAX_SKEW_MS = 5 * 60_000;

/**
 * The bin confirms a deposit. Authenticated by the bin's own HMAC key (no
 * user token). Pays the person whose session is open at that bin; the same
 * `eventId` is paid at most once, and re-sending it returns the first result.
 */
export async function deviceDeposit(
  { store, now }: Deps,
  secret: string,
  input: { binId?: unknown; eventId?: unknown; grams?: unknown; ts?: unknown; mac?: unknown },
): Promise<DepositResult> {
  const binId = typeof input.binId === 'string' && BIN_ID.test(input.binId) ? input.binId : null;
  const eventId = typeof input.eventId === 'string' && EVENT_ID.test(input.eventId) ? input.eventId : null;
  const grams = typeof input.grams === 'number' && Number.isInteger(input.grams) && input.grams >= 0 && input.grams <= CONFIG.maxSingleWeightG ? input.grams : null;
  const ts = typeof input.ts === 'number' && Number.isSafeInteger(input.ts) ? input.ts : null;
  if (!binId || !eventId || grams === null || ts === null) throw Errors.invalid('Bad deposit message');
  if (!verifyDepositMac(deviceKey(secret, binId), { binId, eventId, grams, ts }, input.mac)) {
    throw Errors.forbidden();
  }
  if (Math.abs(now - ts) > MAX_SKEW_MS) throw Errors.invalid('Stale message');
  const bin = await store.get<any>(`devices/${binId}`);
  if (bin === null) throw Errors.notFound('Bin');
  if (bin.disabled === true) throw Errors.binDisabled();
  await store.update(`devices/${binId}`, { lastSeen: now });

  const eventKey = `weightEvents/${binId}_${eventId}`;
  const prev = await store.get<any>(eventKey);
  if (prev && typeof prev.ep === 'number') {
    return { ep: prev.ep, grams: prev.grams, balance: prev.balance, baseEp: prev.baseEp, multiplier: prev.multiplier, duplicate: true };
  }

  const active = await store.get<Active>(`binActive/${binId}`);
  if (!active || active.status !== 'open' || active.exp <= now) throw Errors.noSession();
  const uid = active.uid;

  // Close the session first: exactly one deposit can win it.
  const close = await store.transaction(`binActive/${binId}`, (cur) =>
    (cur as Active | null)?.sid === active.sid && (cur as Active).status === 'open' ? null : undefined,
  );
  if (!close.committed) throw Errors.noSession();
  const claim = await store.transaction(eventKey, (cur) => (cur ? undefined : { uid, ts: now, grams }));
  if (!claim.committed) throw Errors.duplicate('Deposit already processed');

  try {
    const user = await store.get<any>(`users/${uid}`);
    const pro = isProActive(user, now);
    const reward = grams > 0 ? weightReward(grams, pro) : scanReward(pro);
    if (reward.ep <= 0) throw Errors.invalid('Deposit too small');
    await reserveDaily(store, uid, dayKey(now), { ep: reward.ep, scans: 1, grams });
    const tag = reward.multiplier > 1 ? ` ⚡ ${reward.multiplier}×PRO` : '';
    const what = grams > 0 ? `${grams} g` : 'QR';
    const balance = await credit(
      store,
      uid,
      reward.ep,
      { type: 'earn', desc: `♻️ ${what} (${binId})${tag} — ${reward.ep} EP` },
      now,
      { earned: true },
    );
    await increment(store, `users/${uid}/stats/scans`, 1);
    const result = { ep: reward.ep, grams, balance, baseEp: reward.baseEp, multiplier: reward.multiplier };
    await store.set(eventKey, { uid, ts: now, ...result });
    await store.update(`qrSessions/${active.sid}`, { status: 'done', result, doneAt: now });
    return result;
  } catch (e) {
    await store.remove(eventKey);
    await store.update(`qrSessions/${active.sid}`, {
      status: 'failed',
      reason: (e as { reason?: string })?.reason ?? 'internal',
    });
    throw e;
  }
}

/**
 * Virtual bin for development: builds a correctly signed deposit message and
 * feeds it through the very same path a real bin uses. Only when SIM_ENABLED.
 */
export async function simulateDeposit(
  deps: Deps,
  secret: string,
  input: { binId: unknown; grams: unknown },
): Promise<DepositResult> {
  if (!deps.sim) throw Errors.forbidden();
  const binId = typeof input.binId === 'string' && BIN_ID.test(input.binId) ? input.binId : null;
  const grams = typeof input.grams === 'number' && Number.isInteger(input.grams) ? input.grams : 0;
  if (!binId) throw Errors.invalid('Invalid bin id');
  const eventId = randomCode(12, secureRng).toLowerCase();
  const mac = depositMac(deviceKey(secret, binId), { binId, eventId, grams, ts: deps.now });
  return deviceDeposit(deps, secret, { binId, eventId, grams, ts: deps.now, mac });
}
