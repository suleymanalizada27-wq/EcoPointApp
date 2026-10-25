import { CONFIG, MISSIONS } from '../lib/config';
import {
  isMissionId,
  liveStreak,
  missionComplete,
  nextStreak,
  normalizeCode,
  resolveDay,
} from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import { assertNotBanned, credit } from './wallet';

export interface CheckInResult {
  streak: number;
  bonus: number;
  alreadyDone: boolean;
}

/** Records today's check-in; pays the streak bonus every 7th consecutive day. */
export async function claimDailyCheckIn(
  { store, now }: Deps,
  uid: string,
  clientDay: unknown,
): Promise<CheckInResult> {
  await assertNotBanned(store, uid);
  const today = resolveDay(clientDay, now);

  let outcome: ReturnType<typeof nextStreak> | null = null;
  const res = await store.transaction(`users/${uid}/streak`, (cur) => {
    const r = nextStreak(cur, today);
    outcome = r;
    // Keep the stored value unchanged when already checked in.
    return r.alreadyDone ? (cur ?? r.state) : r.state;
  });
  const r = outcome as ReturnType<typeof nextStreak> | null;
  const stored = res.value as { count?: number } | null;
  if (!r) throw Errors.invalid('Check-in failed');
  if (r.alreadyDone) {
    return { streak: Number(stored?.count ?? r.state.count), bonus: 0, alreadyDone: true };
  }
  if (r.bonus > 0) {
    await credit(
      store,
      uid,
      r.bonus,
      { type: 'bonus', desc: `🔥 ${r.state.count}-day streak bonus` },
      now,
      { earned: true },
    );
  }
  return { streak: r.state.count, bonus: r.bonus, alreadyDone: false };
}

/** Pays a daily mission once per day, after recomputing progress itself. */
export async function claimChallenge(
  { store, now }: Deps,
  uid: string,
  input: { challengeId: unknown; day: unknown },
): Promise<{ ep: number }> {
  if (!isMissionId(input.challengeId)) throw Errors.invalid('Unknown challenge');
  const id = input.challengeId;
  await assertNotBanned(store, uid);
  const day = resolveDay(input.day, now);

  const daily = await store.get<any>(`users/${uid}/daily/${day}`);
  const scansToday = Number(daily?.scans ?? 0);
  const streak = liveStreak(await store.get(`users/${uid}/streak`), day);
  if (!missionComplete(id, scansToday, streak)) {
    throw Errors.invalid('Challenge not complete');
  }

  const key = `users/${uid}/claims/${id}_${day}`;
  const claim = await store.transaction(key, (cur) =>
    cur === null || cur === undefined ? now : undefined,
  );
  if (!claim.committed) throw Errors.duplicate('Already claimed');

  const ep = MISSIONS[id].ep;
  try {
    await credit(
      store,
      uid,
      ep,
      { type: 'bonus', desc: `🎯 Mission: ${id}` },
      now,
      { earned: true },
    );
  } catch (e) {
    await store.remove(key);
    throw e;
  }
  return { ep };
}

/** Both sides get the bonus; one referrer per account, capped per referrer. */
export async function applyReferral(
  { store, now }: Deps,
  uid: string,
  input: { code: unknown; accountCreatedAt?: number },
): Promise<{ bonus: number }> {
  const code = normalizeCode(input.code);
  if (code.length < 4 || code.length > 12) throw Errors.invalid('Invalid code');
  await assertNotBanned(store, uid);

  if (input.accountCreatedAt !== undefined) {
    const ageDays = (now - input.accountCreatedAt) / 86_400_000;
    if (ageDays > CONFIG.referralWindowDays) throw Errors.invalid('Referral window has passed');
  }

  const referrerUid = await store.get<string>(`referralCodes/${code}`);
  if (typeof referrerUid !== 'string') throw Errors.notFound('Code');
  if (referrerUid === uid) throw Errors.invalid('Cannot use your own code');

  // One referrer per account (atomic).
  const claim = await store.transaction(`users/${uid}/referredBy`, (cur) =>
    cur === null || cur === undefined ? referrerUid : undefined,
  );
  if (!claim.committed) throw Errors.duplicate('Referral already applied');

  // Referrer cap (atomic).
  let allowed = false;
  await store.transaction(`users/${referrerUid}/referralCount`, (cur) => {
    const n = typeof cur === 'number' ? cur : 0;
    allowed = n < CONFIG.maxReferralsPerUser;
    return allowed ? n + 1 : undefined;
  });
  if (!allowed) {
    await store.remove(`users/${uid}/referredBy`);
    throw Errors.invalid('Referral limit reached for this code');
  }

  const bonus = CONFIG.referralBonusEp;
  await credit(store, uid, bonus, { type: 'bonus', desc: '🎁 Referral bonus' }, now, { earned: true });
  await credit(store, referrerUid, bonus, { type: 'bonus', desc: '🎁 Referral bonus' }, now, {
    earned: true,
  });
  return { bonus };
}
