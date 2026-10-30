import { BUILT_IN_CATALOG } from '../catalog';
import { MONTHLY } from '../lib/config';
import { bakuHour, dayKey, liveStreak } from '../lib/rules';
import { smartText, type SmartKind, type SmartVars } from '../lib/notify-text';
import type { Store } from '../store';
import { forEachPushUser, userLang, type ReminderEnv, type RunResult } from './reminders';

/** Earliest / latest local hour a personal push may be sent. */
export const SEND_FROM = 9;
export const SEND_UNTIL = 21; // exclusive
const DEFAULT_HOUR = 12;
const WINDOW_HOURS = 3;

/** Days before the same kind may be sent again to the same person. */
const COOLDOWN_DAYS: Record<SmartKind, number> = {
  monthlyReady: 2,
  monthlyClose: 3,
  rewardClose: 4,
  comeback: 7,
  daily: 1,
};
const MAX_COMEBACKS = 3;

interface Facts {
  name: string;
  today: string;
  streak: ReturnType<typeof liveStreak>;
  checkedInToday: boolean;
  scansMonth: number;
  claimedMonthly: Set<string>;
  daysLeftInMonth: number;
  balance: number;
  lastScanDay: string | null;
  daysSinceScan: number | null;
}

export interface RewardLite {
  id: string;
  name: string;
  ep: number;
}

export interface Pick {
  kind: SmartKind;
  vars: SmartVars;
  route: string;
}

const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);

/** Preferred send hour = one hour before the person's most common scan hour. */
export function sendHourFor(habit: Record<string, unknown> | null): number {
  let best = -1;
  let bestN = 0;
  let total = 0;
  for (let h = 0; h < 24; h++) {
    const n = num(habit?.[`h${h}`]);
    total += n;
    if (n > bestN) {
      bestN = n;
      best = h;
    }
  }
  if (best < 0 || total < 3) return DEFAULT_HOUR;
  return Math.min(SEND_UNTIL - 1, Math.max(SEND_FROM, best - 1));
}

/** Pure priority logic: the single most useful message right now, or null. */
export function pickMessage(
  f: Facts,
  rewards: RewardLite[],
  allow: { activity: boolean; offers: boolean },
  lastSent: Partial<Record<SmartKind, number>>,
  comebackCount: number,
  now: number,
): Pick | null {
  const ready = (k: SmartKind) =>
    !lastSent[k] || now - (lastSent[k] as number) >= COOLDOWN_DAYS[k] * 86_400_000;
  const goals = (Object.entries(MONTHLY) as Array<[string, { ep: number; goal: number }]>).sort(
    (a, b) => a[1].goal - b[1].goal,
  );

  if (allow.activity) {
    const done = goals.find(([id, g]) => f.scansMonth >= g.goal && !f.claimedMonthly.has(id));
    if (done && ready('monthlyReady')) {
      return { kind: 'monthlyReady', vars: { name: f.name, goal: done[1].goal, ep: done[1].ep }, route: '/challenges' };
    }
    const next = goals.find(([id, g]) => f.scansMonth < g.goal && !f.claimedMonthly.has(id));
    if (next) {
      const left = next[1].goal - f.scansMonth;
      if (f.scansMonth > 0 && left <= Math.ceil(next[1].goal * 0.2) && ready('monthlyClose')) {
        return {
          kind: 'monthlyClose',
          vars: { name: f.name, goal: next[1].goal, left, days: f.daysLeftInMonth },
          route: '/challenges',
        };
      }
    }
  }

  if (allow.offers) {
    let best: { r: RewardLite; gap: number } | null = null;
    for (const r of rewards) {
      const gap = r.ep - f.balance;
      if (gap > 0 && gap <= Math.max(60, Math.round(r.ep * 0.25)) && (!best || gap < best.gap)) {
        best = { r, gap };
      }
    }
    if (best && ready('rewardClose')) {
      return { kind: 'rewardClose', vars: { name: f.name, reward: best.r.name, gap: best.gap }, route: '/rewards' };
    }
    if (
      f.daysSinceScan !== null &&
      f.daysSinceScan >= 7 &&
      comebackCount < MAX_COMEBACKS &&
      ready('comeback')
    ) {
      return { kind: 'comeback', vars: { name: f.name, days: f.daysSinceScan }, route: '/scan' };
    }
  }

  if (allow.activity && !f.checkedInToday && ready('daily')) {
    return { kind: 'daily', vars: { name: f.name, streak: f.streak }, route: '/home' };
  }
  return null;
}

function daysBetweenKeys(a: string, b: string): number {
  return Math.round((Date.parse(`${b}T00:00:00Z`) - Date.parse(`${a}T00:00:00Z`)) / 86_400_000);
}

async function rewardList(store: Store, lang: 'az' | 'en' | 'ru' | 'tr'): Promise<RewardLite[]> {
  const all = await store.get<Record<string, any>>('rewards');
  const rows =
    all && Object.keys(all).length > 0
      ? Object.entries(all).map(([id, r]) => ({ id, ...r }))
      : BUILT_IN_CATALOG.map((c) => ({ ...c }));
  return rows
    .filter((r: any) => r.kind === 'item' && r.active !== false && typeof r.ep === 'number' && (r.stock === undefined || r.stock > 0))
    .map((r: any) => ({ id: String(r.id), name: String(r.name?.[lang] ?? r.name?.az ?? r.id), ep: r.ep as number }));
}

/**
 * Hourly job. Sends at most ONE personal push per person per day, at the
 * person's own preferred hour (default 12:00), only between 09:00 and 21:00
 * Baku time, never the same kind inside its cool-down, and only what the
 * person allowed in notification settings.
 */
export async function runSmartPush(env: ReminderEnv): Promise<RunResult> {
  const { store, now } = env;
  const hour = bakuHour(now);
  if (hour < SEND_FROM || hour >= SEND_UNTIL) return { considered: 0, sent: 0 };
  const today = dayKey(now);
  const month = today.slice(0, 7);
  const [y, m] = month.split('-').map(Number);
  const daysInMonth = new Date(Date.UTC(y, m, 0)).getUTCDate();
  const daysLeft = Math.max(0, daysInMonth - Number(today.slice(8, 10)));

  const rewardsByLang: Partial<Record<'az' | 'en' | 'ru' | 'tr', RewardLite[]>> = {};

  return forEachPushUser(env, async (uid) => {
    const log = (await store.get<any>(`pushLog/${uid}`)) ?? {};
    if (log.lastDay === today) return false;

    const habit = await store.get<Record<string, unknown>>(`users/${uid}/habit`);
    const sendHour = sendHourFor(habit);
    if (hour < sendHour || hour >= sendHour + WINDOW_HOURS) return false;

    const prefs = (await store.get<any>(`users/${uid}/prefs`)) ?? {};
    const allow = { activity: prefs.notifyActivity !== false, offers: prefs.notifyOffers !== false };
    if (!allow.activity && !allow.offers) return false;

    const [name, balance, streakRaw, daily, scansMonth, claims, lang] = await Promise.all([
      store.get<string>(`users/${uid}/name`),
      store.get<number>(`users/${uid}/balance`),
      store.get<any>(`users/${uid}/streak`),
      store.get<Record<string, { scans?: number }>>(`users/${uid}/daily`),
      store.get<number>(`users/${uid}/monthly/${month}/scans`),
      store.get<Record<string, unknown>>(`users/${uid}/claims`),
      userLang(store, uid),
    ]);

    let lastScanDay: string | null = null;
    for (const [d, v] of Object.entries(daily ?? {})) {
      if (num(v?.scans) > 0 && (!lastScanDay || d > lastScanDay)) lastScanDay = d;
    }
    const claimedMonthly = new Set(
      Object.keys(claims ?? {})
        .filter((k) => k.startsWith('m_') && k.endsWith(`_${month}`))
        .map((k) => k.slice(0, k.length - month.length - 1)),
    );
    const facts: Facts = {
      name: String(name ?? '').trim().split(/\s+/)[0]?.slice(0, 20) ?? '',
      today,
      streak: liveStreak(streakRaw, today),
      checkedInToday: streakRaw?.lastDay === today,
      scansMonth: num(scansMonth),
      claimedMonthly,
      daysLeftInMonth: daysLeft,
      balance: num(balance),
      lastScanDay,
      daysSinceScan: lastScanDay ? daysBetweenKeys(lastScanDay, today) : null,
    };
    // A brand-new account has nothing to report yet.
    if (!lastScanDay && facts.balance === 0 && !facts.streak) return false;

    rewardsByLang[lang] ??= await rewardList(store, lang);
    const lastSent: Partial<Record<SmartKind, number>> = log.kinds ?? {};
    const pick = pickMessage(facts, rewardsByLang[lang] ?? [], allow, lastSent, num(log.comebacks), now);
    if (!pick) return false;

    // Claim "today" atomically so a restart or overlapping tick never double-sends.
    const claim = await store.transaction(`pushLog/${uid}/lastDay`, (cur) => (cur === today ? undefined : today));
    if (!claim.committed) return false;

    const text = smartText(lang, pick.kind, pick.vars);
    await env.push.toUser(uid, { ...text, route: pick.route });
    await store.update(`pushLog/${uid}`, {
      last: now,
      lastKind: pick.kind,
      [`kinds/${pick.kind}`]: now,
      ...(pick.kind === 'comeback' ? { comebacks: num(log.comebacks) + 1 } : {}),
    });
    return true;
  });
}
