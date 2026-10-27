import { dayKey } from '../lib/rules';
import type { Store } from '../store';

export type StatField = 'signups' | 'earnedEp' | 'spentEp' | 'earns' | 'purchases';

const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);

/** Best-effort daily counter for the admin charts. Never blocks real work. */
export async function bumpStat(store: Store, now: number, field: StatField, by = 1): Promise<void> {
  try {
    await store.transaction(`statsDaily/${dayKey(now)}/${field}`, (cur) => num(cur) + by);
  } catch {
    /* statistics must never break a payment */
  }
}

/** Counts how often a reward was bought (for the "top rewards" list). */
export async function bumpReward(store: Store, rewardKey: string, label: string, now: number): Promise<void> {
  try {
    const key = rewardKey.replace(/[.#$/[\]]/g, '_').slice(0, 40);
    await store.transaction(`statsRewards/${key}/count`, (cur) => num(cur) + 1);
    await store.update(`statsRewards/${key}`, { name: label.slice(0, 60), last: now });
  } catch {
    /* ignore */
  }
}

export interface StatsResult {
  days: Array<{ day: string; signups: number; earnedEp: number; spentEp: number; earns: number; purchases: number }>;
  topRewards: Array<{ name: string; count: number }>;
}

export async function adminStats(store: Store, now: number, span = 14): Promise<StatsResult> {
  const all = (await store.get<Record<string, any>>('statsDaily')) ?? {};
  const days: StatsResult['days'] = [];
  for (let i = span - 1; i >= 0; i--) {
    const day = dayKey(now - i * 86_400_000);
    const d = all[day] ?? {};
    days.push({
      day,
      signups: num(d.signups),
      earnedEp: num(d.earnedEp),
      spentEp: num(d.spentEp),
      earns: num(d.earns),
      purchases: num(d.purchases),
    });
  }
  const rewards = (await store.get<Record<string, any>>('statsRewards')) ?? {};
  const topRewards = Object.values(rewards)
    .map((r) => ({ name: String(r?.name ?? '—'), count: num(r?.count) }))
    .filter((r) => r.count > 0)
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);
  return { days, topRewards };
}
