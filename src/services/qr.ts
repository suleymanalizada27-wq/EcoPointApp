import { CONFIG } from '../lib/config';
import { parseCode, verifySignature } from '../lib/qr';
import { isProActive, scanReward, dayKey } from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import { assertNotBanned, credit, increment, rateLimit, reserveDaily } from './wallet';

export interface RedeemQrResult {
  ep: number;
  baseEp: number;
  multiplier: number;
  balance: number;
  binId: string;
}

/**
 * The ONLY place a bin QR code can turn into EP. Order matters:
 * 1. format + HMAC signature  (forged codes never reach the database)
 * 2. expiry
 * 3. rate limits
 * 4. single-use nonce claim   (replays and double-scans)
 * 5. daily cap, then the credit
 */
export async function redeemQr(
  { store, now }: Deps,
  secret: string,
  uid: string,
  payload: unknown,
): Promise<RedeemQrResult> {
  const code = parseCode(payload);
  if (!code || !verifySignature(secret, code)) throw Errors.invalidQr();
  if (code.exp * 1000 <= now) throw Errors.expiredQr();

  await assertNotBanned(store, uid);
  const bin = await store.get(`devices/${code.binId}`);
  if (bin === null) throw Errors.invalidQr('Unknown bin');

  await rateLimit(store, `scan/${uid}`, now, {
    windowMs: 3_600_000,
    max: CONFIG.maxScansPerHour,
    minIntervalMs: CONFIG.minScanIntervalMs,
  });

  const user = await store.get<any>(`users/${uid}`);
  const reward = scanReward(isProActive(user, now));

  const nonceKey = `qrNonces/${code.binId}_${code.nonce}`;
  const claim = await store.transaction(nonceKey, (cur) =>
    cur === null || cur === undefined ? { uid, ts: now, exp: code.exp } : undefined,
  );
  if (!claim.committed) throw Errors.duplicate('QR code already used');

  try {
    const day = dayKey(now);
    await reserveDaily(store, uid, day, { ep: reward.ep, scans: 1 });
    const tag = reward.multiplier > 1 ? ` ⚡ ${reward.multiplier}×PRO` : '';
    const balance = await credit(
      store,
      uid,
      reward.ep,
      { type: 'earn', desc: `♻️ QR scan (${code.binId})${tag} — ${reward.ep} EP` },
      now,
      { earned: true },
    );
    await increment(store, `users/${uid}/stats/scans`, 1);
    return { ...reward, balance, binId: code.binId };
  } catch (e) {
    // Nothing was paid: free the code so the legitimate holder can retry.
    await store.remove(nonceKey);
    throw e;
  }
}
