import { CONFIG } from '../lib/config';
import { dayKey, isProActive, weightReward } from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import { assertNotBanned, credit, rateLimit, reserveDaily } from './wallet';

/**
 * Pays EP for the weight currently reported by a smart bin's scale.
 *
 * The legacy client trusted a `pendingPoints` node that the *client itself*
 * wrote, so anyone could mint EP. Here the server reads the device's own
 * reading and makes each reading single-use through `weightEventId`, which
 * the bin firmware must increment for every new deposit.
 */
export async function redeemDeviceWeight(
  { store, now }: Deps,
  uid: string,
  input: { deviceId: unknown },
): Promise<{ ep: number; grams: number; balance: number }> {
  const deviceId = typeof input.deviceId === 'string' ? input.deviceId : '';
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(deviceId)) throw Errors.invalid('Invalid device');
  await assertNotBanned(store, uid);

  await rateLimit(store, `weight/${uid}`, now, { windowMs: 5 * 60_000, max: 5 });

  const device = await store.get<any>(`devices/${deviceId}`);
  if (!device) throw Errors.notFound('Device');

  const eventId = device.weightEventId;
  if (eventId === undefined || eventId === null || eventId === '') {
    throw Errors.invalid('This bin does not support weight redemption');
  }
  const seen = Number(device.lastSeen ?? 0);
  if (!(seen > 0) || now - seen > CONFIG.deviceFreshnessMs) {
    throw Errors.invalid('Bin is offline');
  }
  const grams = Math.floor(Number(device.weight ?? 0));
  if (!Number.isFinite(grams) || grams < CONFIG.minWeightG) {
    throw Errors.invalid('Minimum weight is 100 g');
  }
  if (grams > CONFIG.maxSingleWeightG) throw Errors.invalid('Reading looks invalid');

  // Each reading can be redeemed exactly once.
  const eventKey = `weightEvents/${deviceId}_${String(eventId).replace(/[^A-Za-z0-9_-]/g, '_')}`;
  const claim = await store.transaction(eventKey, (cur) =>
    cur === null || cur === undefined ? { uid, ts: now, grams } : undefined,
  );
  if (!claim.committed) throw Errors.duplicate('Reading already redeemed');

  // Per-bin cooldown. Checked only after a successful claim so that failed
  // attempts (e.g. replays) cannot be used to lock other people out.
  let cooling = false;
  await store.transaction(`deviceState/${deviceId}/lastRedeem`, (cur) => {
    const last = Number((cur as any)?.ts ?? 0);
    cooling = last > 0 && now - last < CONFIG.weightCooldownMs;
    return cooling ? undefined : { ts: now, uid };
  });
  if (cooling) {
    await store.remove(eventKey);
    throw Errors.rateLimited();
  }

  try {
    const user = await store.get<any>(`users/${uid}`);
    const reward = weightReward(grams, isProActive(user, now));
    if (reward.ep <= 0) throw Errors.invalid('Minimum weight is 100 g');
    await reserveDaily(store, uid, dayKey(now), { ep: reward.ep, grams });
    const tag = reward.multiplier > 1 ? ` ⚡ ${reward.multiplier}×PRO` : '';
    const balance = await credit(
      store,
      uid,
      reward.ep,
      { type: 'weight', desc: `⚖️ ${grams} g${tag} → ${reward.ep} EP` },
      now,
      { earned: true },
    );
    return { ep: reward.ep, grams, balance };
  } catch (e) {
    await store.remove(eventKey);
    throw e;
  }
}
