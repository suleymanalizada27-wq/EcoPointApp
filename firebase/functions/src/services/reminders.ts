import { dayKey, liveStreak, previousDay } from '../lib/rules';
import {
  asLang,
  dailyReminderText,
  streakRiskText,
  weeklySummaryText,
  type Lang,
} from '../lib/notify-text';
import type { PushSender } from '../push';
import type { Store } from '../store';

export interface ReminderEnv {
  store: Store;
  push: PushSender;
  now: number;
  /** Max people processed in parallel. */
  concurrency?: number;
}

export interface RunResult {
  considered: number;
  sent: number;
}

/** Language of the user's most recently registered device (default az). */
async function userLang(store: Store, uid: string): Promise<Lang> {
  const rows = await store.get<Record<string, { lang?: unknown; ts?: number }>>(`pushTokens/${uid}`);
  let best: { lang?: unknown; ts?: number } | null = null;
  for (const v of Object.values(rows ?? {})) {
    if (!best || (v?.ts ?? 0) >= (best.ts ?? 0)) best = v;
  }
  return asLang(best?.lang);
}

async function forEachPushUser(
  env: ReminderEnv,
  fn: (uid: string) => Promise<boolean>,
): Promise<RunResult> {
  const index = (await env.store.get<Record<string, unknown>>('pushUsers')) ?? {};
  const uids = Object.keys(index);
  const size = Math.max(1, env.concurrency ?? 10);
  let sent = 0;
  for (let i = 0; i < uids.length; i += size) {
    const chunk = uids.slice(i, i + size);
    const results = await Promise.all(
      chunk.map(async (uid) => {
        try {
          return await fn(uid);
        } catch {
          return false;
        }
      }),
    );
    sent += results.filter(Boolean).length;
  }
  return { considered: uids.length, sent };
}

const wantsActivity = async (store: Store, uid: string): Promise<boolean> =>
  (await store.get<boolean>(`users/${uid}/prefs/notifyActivity`)) !== false;

/** Not yet checked in today → friendly nudge (mentions a live streak). */
export function runDailyReminder(env: ReminderEnv): Promise<RunResult> {
  const today = dayKey(env.now);
  return forEachPushUser(env, async (uid) => {
    if (!(await wantsActivity(env.store, uid))) return false;
    const streak = await env.store.get<any>(`users/${uid}/streak`);
    if (streak?.lastDay === today) return false;
    const text = dailyReminderText(await userLang(env.store, uid), liveStreak(streak, today));
    await env.push.toUser(uid, text);
    return true;
  });
}

/** Evening: a streak of ≥ `minStreak` days that will reset if not continued. */
export function runStreakRisk(env: ReminderEnv, minStreak = 3): Promise<RunResult> {
  const today = dayKey(env.now);
  return forEachPushUser(env, async (uid) => {
    if (!(await wantsActivity(env.store, uid))) return false;
    const streak = await env.store.get<any>(`users/${uid}/streak`);
    // Alive (checked in yesterday) but not yet today.
    if (streak?.lastDay !== previousDay(today)) return false;
    const n = liveStreak(streak, today);
    if (n < minStreak) return false;
    await env.push.toUser(uid, streakRiskText(await userLang(env.store, uid), n));
    return true;
  });
}

/** Monday: real totals of the previous 7 days; skipped when there is nothing to report. */
export function runWeeklySummary(env: ReminderEnv): Promise<RunResult> {
  const today = dayKey(env.now);
  const days: string[] = [];
  let d = today;
  for (let i = 0; i < 7; i++) {
    d = previousDay(d);
    days.push(d);
  }
  return forEachPushUser(env, async (uid) => {
    if (!(await wantsActivity(env.store, uid))) return false;
    const daily = (await env.store.get<Record<string, { ep?: number; scans?: number }>>(
      `users/${uid}/daily`,
    )) ?? {};
    let ep = 0;
    let scans = 0;
    for (const day of days) {
      ep += Number(daily[day]?.ep ?? 0) || 0;
      scans += Number(daily[day]?.scans ?? 0) || 0;
    }
    if (ep <= 0) return false;
    await env.push.toUser(uid, weeklySummaryText(await userLang(env.store, uid), ep, scans));
    return true;
  });
}
