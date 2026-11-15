import { BUILT_IN_CATALOG } from '../catalog';
import { MISSIONS, MONTHLY } from '../lib/config';
import { dayKey, liveStreak, missionComplete, weekKey } from '../lib/rules';
import { extraText, smartText, TIP_COUNT, type Lang, type SmartKind, type SmartVars } from '../lib/notify-text';
import type { Store } from '../store';
import { forEachPushUser, userLang, type ReminderEnv, type RunResult } from './reminders';

/** Earliest / latest local hour a personal push may be sent. */
export const SEND_FROM = 9;
export const SEND_UNTIL = 21; // exclusive
const DEFAULT_HOUR = 12;
/** Daily amount: adaptive between these (v2). */
export const MIN_CAP = 4;
export const MAX_CAP = 9;
const COMEBACK_CAP = 2;

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

async function rewardList(store: Store, lang: Lang): Promise<RewardLite[]> {
  const all = await store.get<Record<string, any>>('rewards');
  const rows =
    all && Object.keys(all).length > 0
      ? Object.entries(all).map(([id, r]) => ({ id, ...r }))
      : BUILT_IN_CATALOG.map((c) => ({ ...c }));
  return rows
    .filter((r: any) => r.kind === 'item' && r.active !== false && typeof r.ep === 'number' && (r.stock === undefined || r.stock > 0))
    .map((r: any) => ({ id: String(r.id), name: String(r.name?.[lang] ?? r.name?.en ?? r.name?.az ?? r.id), ep: r.ep as number }));
}

/** Minutes east of UTC of the person's most recent device (default Baku). */
export async function userTz(store: Store, uid: string): Promise<number> {
  const rows = await store.get<Record<string, { tz?: unknown; ts?: number }>>(`pushTokens/${uid}`);
  let best: { tz?: unknown; ts?: number } | null = null;
  for (const v of Object.values(rows ?? {})) if (!best || (v?.ts ?? 0) >= (best.ts ?? 0)) best = v;
  return typeof best?.tz === 'number' ? best.tz : 240;
}

/** Local day key and hour for an offset in minutes. */
export function localClock(now: number, tzMin: number): { day: string; hour: number } {
  const d = new Date(now + tzMin * 60_000);
  return { day: d.toISOString().slice(0, 10), hour: d.getUTCHours() };
}

export type Freq = 'low' | 'normal' | 'high';

/** Reads the frequency choice (legacy `notifyFewer` meant "low"). */
export function freqOf(prefs: { notifyFreq?: unknown; notifyFewer?: unknown }): Freq {
  if (prefs.notifyFreq === 'low' || prefs.notifyFreq === 'normal' || prefs.notifyFreq === 'high') {
    return prefs.notifyFreq;
  }
  return prefs.notifyFewer === true ? 'low' : 'normal';
}

/**
 * How many pushes today. "low" = 2, "high" = 9. "normal" adapts between 4 and
 * 9: +1 for every day in the last 7 on which the person tapped a push. After
 * 7 days without a scan everyone is in comeback mode (2 a day at most).
 */
export function dailyCap(opensLast7: number, inactiveDays: number | null, freq: unknown): number {
  if (inactiveDays !== null && inactiveDays >= 7) return COMEBACK_CAP;
  if (freq === 'low') return 2;
  if (freq === 'high') return MAX_CAP;
  return Math.min(MAX_CAP, MIN_CAP + Math.max(0, Math.min(5, opensLast7)));
}

/** Hours of the day outside the person's quiet hours (default 22:00–09:00). */
export function allowedHours(quietFrom: unknown, quietTo: unknown): number[] {
  const f = typeof quietFrom === 'number' && Number.isInteger(quietFrom) && quietFrom >= 0 && quietFrom <= 23 ? quietFrom : 22;
  const t = typeof quietTo === 'number' && Number.isInteger(quietTo) && quietTo >= 0 && quietTo <= 23 ? quietTo : 9;
  const out: number[] = [];
  for (let h = 0; h < 24; h++) {
    const quiet = f === t ? false : f < t ? h >= f && h < t : h >= f || h < t;
    if (!quiet) out.push(h);
  }
  return out;
}

/** Evenly spread send hours inside the allowed hours. */
export function slotHours(cap: number, allowed: number[] = allowedHours(undefined, undefined)): number[] {
  const n = Math.max(1, Math.min(MAX_CAP, cap, allowed.length));
  return Array.from({ length: n }, (_, i) => allowed[Math.floor((i * allowed.length) / n)]);
}

/** Highest-priority personal extra: milestone → mission → leaderboard. */
export function pickExtra(
  f: { name: string; streak: number; checkedInToday: boolean },
  scansToday: number,
  claimedToday: Set<string>,
  rank: { rank: number; gap: number | null } | null,
  lastSent: Partial<Record<string, number>>,
  now: number,
  allow: { activity: boolean; missions: boolean },
): { kind: 'milestone' | 'mission' | 'leaderboard'; vars: Record<string, number>; route: string } | null {
  const gapOk = (k: string, days: number) => !lastSent[k] || now - (lastSent[k] as number) >= days * 86_400_000;
  if (allow.activity && f.checkedInToday && [7, 14, 30, 60, 100].includes(f.streak) && gapOk('milestone', 20)) {
    return { kind: 'milestone', vars: { streak: f.streak }, route: '/challenges' };
  }
  if (allow.missions && gapOk('mission', 1)) {
    let best: { ep: number; left: number } | null = null;
    for (const [id, m] of Object.entries(MISSIONS) as Array<[keyof typeof MISSIONS, (typeof MISSIONS)[keyof typeof MISSIONS]]>) {
      if (claimedToday.has(id)) continue;
      const progress = m.kind === 'scansToday' ? scansToday : f.streak;
      if (missionComplete(id, scansToday, f.streak)) {
        best = { ep: m.ep, left: 0 };
        break;
      }
      const left = m.goal - progress;
      if (m.kind === 'scansToday' && progress >= 1 && left <= 2 && (!best || left < best.left)) {
        best = { ep: m.ep, left };
      }
    }
    if (best) return { kind: 'mission', vars: { ep: best.ep, left: best.left }, route: '/challenges' };
  }
  if (allow.missions && rank && gapOk('leaderboard', 2)) {
    if (rank.rank <= 3) return { kind: 'leaderboard', vars: { rank: rank.rank }, route: '/leaderboard' };
    if (rank.gap !== null && rank.gap > 0 && rank.gap <= 60) {
      return { kind: 'leaderboard', vars: { rank: rank.rank, gap: rank.gap }, route: '/leaderboard' };
    }
  }
  return null;
}

export interface RankRow {
  rank: number;
  gap: number | null;
}

/** This week's ranking (EP), computed once per run. */
export async function weeklyRanks(store: Store, now: number): Promise<Map<string, RankRow>> {
  const board = (await store.get<Record<string, { ep?: number }>>(`weeklyBoard/${weekKey(now)}`)) ?? {};
  const rows = Object.entries(board)
    .map(([uid, v]) => ({ uid, ep: num(v?.ep) }))
    .filter((r) => r.ep > 0)
    .sort((a, b) => b.ep - a.ep);
  const out = new Map<string, RankRow>();
  rows.forEach((r, i) => out.set(r.uid, { rank: i + 1, gap: i === 0 ? null : rows[i - 1].ep - r.ep + 1 }));
  return out;
}

/** Counts a sent/opened push for the admin statistics (server-side only). */
export async function countPush(store: Store, now: number, field: 'sent' | 'opened', kind: string): Promise<void> {
  try {
    await store.transaction(`pushStats/${dayKey(now)}/${field}/${kind}`, (c) => (typeof c === 'number' ? c : 0) + 1);
  } catch {
    /* statistics must never block a push */
  }
}

/** Admin master switch (config/pushDisabled). */
export async function pushIsDisabled(store: Store): Promise<boolean> {
  return (await store.get<boolean>('config/pushDisabled')) === true;
}

/**
 * Hourly job (v2). Each person has up to `dailyCap` slots spread over the
 * hours that are not their quiet hours (device time zone). A slot sends the
 * most useful message that is still valid at send time, otherwise stays
 * silent. Slots are claimed atomically, so overlapping ticks or two
 * schedulers never double-send.
 */
export async function runSmartPush(env: ReminderEnv): Promise<RunResult> {
  const { store, now } = env;
  if (await pushIsDisabled(store)) return { considered: 0, sent: 0 };
  const rewardsByLang: Partial<Record<Lang, RewardLite[]>> = {};
  let ranks: Map<string, RankRow> | null = null;

  return forEachPushUser(env, async (uid) => {
    const tz = await userTz(store, uid);
    const local = localClock(now, tz);

    const prefs = (await store.get<any>(`users/${uid}/prefs`)) ?? {};
    const allowed = allowedHours(prefs.quietFrom, prefs.quietTo);
    if (!allowed.includes(local.hour)) return false;
    const allow = {
      activity: prefs.notifyActivity !== false,
      offers: prefs.notifyOffers !== false,
      missions: prefs.notifyMissions !== false,
      tips: prefs.notifyTips !== false,
    };
    if (!allow.activity && !allow.offers && !allow.missions && !allow.tips) return false;

    const log = (await store.get<any>(`pushLog/${uid}`)) ?? {};
    const sentToday: number = num(log.count?.[local.day]);
    const opens = Object.keys(log.opens ?? {}).filter((d) => d >= localClock(now - 7 * 86_400_000, tz).day).length;

    const today = dayKey(now);
    const month = today.slice(0, 7);
    const [y, m] = month.split('-').map(Number);
    const daysLeft = Math.max(0, new Date(Date.UTC(y, m, 0)).getUTCDate() - Number(today.slice(8, 10)));

    const [name, balance, streakRaw, daily, scansMonth, claims, lang] = await Promise.all([
      store.get<string>(`users/${uid}/name`),
      store.get<number>(`users/${uid}/balance`),
      store.get<any>(`users/${uid}/streak`),
      store.get<Record<string, { scans?: number; ep?: number }>>(`users/${uid}/daily`),
      store.get<number>(`users/${uid}/monthly/${month}/scans`),
      store.get<Record<string, unknown>>(`users/${uid}/claims`),
      userLang(store, uid),
    ]);

    let lastScanDay: string | null = null;
    for (const [d, v] of Object.entries(daily ?? {})) {
      if (num(v?.scans) > 0 && (!lastScanDay || d > lastScanDay)) lastScanDay = d;
    }
    const inactive = lastScanDay ? daysBetweenKeys(lastScanDay, today) : null;
    const cap = dailyCap(opens, inactive, freqOf(prefs));
    if (sentToday >= cap) return false;
    if (!slotHours(cap, allowed).includes(local.hour)) return false;

    const claimedMonthly = new Set(
      Object.keys(claims ?? {})
        .filter((k) => k.startsWith('m_') && k.endsWith(`_${month}`))
        .map((k) => k.slice(0, k.length - month.length - 1)),
    );
    const claimedToday = new Set(
      Object.keys(claims ?? {})
        .filter((k) => k.endsWith(`_${today}`))
        .map((k) => k.slice(0, k.length - today.length - 1)),
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
      daysSinceScan: inactive,
    };
    // A brand-new account has nothing to report yet.
    if (!lastScanDay && facts.balance === 0 && !facts.streak) return false;

    rewardsByLang[lang] ??= await rewardList(store, lang);
    const lastSent: Partial<Record<SmartKind, number>> = log.kinds ?? {};
    const pick = pickMessage(facts, rewardsByLang[lang] ?? [], allow, lastSent, num(log.comebacks), now);

    let text: { title: string; body: string } | null = null;
    let kind: string = '';
    let route = '/home';
    if (pick) {
      text = smartText(lang, pick.kind, pick.vars);
      kind = pick.kind;
      route = pick.route;
    } else {
      if (allow.missions) ranks ??= await weeklyRanks(store, now);
      const extra = pickExtra(
        facts,
        num(daily?.[today]?.scans),
        claimedToday,
        ranks?.get(uid) ?? null,
        log.kinds ?? {},
        now,
        allow,
      );
      if (extra) {
        text = extraText(lang, extra.kind, { name: facts.name, ...extra.vars });
        kind = extra.kind;
        route = extra.route;
      } else if (allow.tips) {
        const todayRow = daily?.[today];
        const tipsToday = num(log.tips?.[local.day]);
        if (local.hour >= 18 && num(todayRow?.ep) > 0 && log.recapDay !== local.day) {
          text = extraText(lang, 'recap', { name: facts.name, ep: num(todayRow?.ep), scans: num(todayRow?.scans) });
          kind = 'recap';
        } else if (tipsToday < Math.max(2, cap - 3)) {
          const index = (num(log.tipIndex) + Number(today.slice(8, 10))) % TIP_COUNT;
          text = extraText(lang, 'tip', { name: facts.name, index });
          kind = 'tip';
          route = '/scan';
        }
      }
    }
    if (!text) return false;

    const slotId = `${local.day}_${String(local.hour).padStart(2, '0')}`;
    const claim = await store.transaction(`pushLog/${uid}/slots/${slotId}`, (cur) => (cur ? undefined : now));
    if (!claim.committed) return false;

    await env.push.toUser(uid, { ...text, route, kind, id: slotId });
    await store.push(`users/${uid}/notifications`, { title: text.title, body: text.body, ts: now, kind });
    await countPush(store, now, 'sent', kind);
    await store.update(`pushLog/${uid}`, {
      last: now,
      lastKind: kind,
      lastDay: today,
      [`count/${local.day}`]: sentToday + 1,
      ...(kind !== 'tip' && kind !== 'recap' ? { [`kinds/${kind}`]: now } : {}),
      ...(pick?.kind === 'comeback' ? { comebacks: num(log.comebacks) + 1 } : {}),
      ...(kind === 'recap' ? { recapDay: local.day } : {}),
      ...(kind === 'tip' ? { [`tips/${local.day}`]: num(log.tips?.[local.day]) + 1, tipIndex: num(log.tipIndex) + 1 } : {}),
    });
    // Housekeeping: keep only the last few days of slot markers.
    const old = Object.keys(log.slots ?? {}).filter((k) => k.slice(0, 10) < localClock(now - 3 * 86_400_000, tz).day);
    await Promise.all(old.map((k) => store.remove(`pushLog/${uid}/slots/${k}`)));
    return true;
  });
}
