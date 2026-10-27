import { CONFIG, MISSIONS, type MissionId } from './config';

// ───────────────────────────── time ─────────────────────────────

/** `yyyy-MM-dd` in the given IANA time zone. */
export function dayKey(nowMs: number, timeZone: string = CONFIG.timeZone): string {
  return new Date(nowMs).toLocaleDateString('sv-SE', { timeZone });
}

const DAY_RE = /^\d{4}-\d{2}-\d{2}$/;

export function isDayKey(v: unknown): v is string {
  return typeof v === 'string' && DAY_RE.test(v) && !Number.isNaN(Date.parse(`${v}T00:00:00Z`));
}

function dayNumber(key: string): number {
  return Math.round(Date.parse(`${key}T00:00:00Z`) / 86_400_000);
}

export function previousDay(key: string): string {
  return new Date((dayNumber(key) - 1) * 86_400_000).toISOString().slice(0, 10);
}

export function daysBetween(a: string, b: string): number {
  return dayNumber(b) - dayNumber(a);
}

/**
 * The client sends its local calendar day. Accept it only when within one day
 * of the server's day (covers every time zone); otherwise use the server's.
 */
export function resolveDay(clientDay: unknown, nowMs: number): string {
  const server = dayKey(nowMs);
  if (isDayKey(clientDay) && Math.abs(daysBetween(server, clientDay)) <= 1) {
    return clientDay;
  }
  return server;
}

// ───────────────────────────── rewards ─────────────────────────────

export function scanReward(isPro: boolean): { baseEp: number; multiplier: number; ep: number } {
  const multiplier = isPro ? CONFIG.proMultiplier : 1;
  return { baseEp: CONFIG.scanBaseEp, multiplier, ep: CONFIG.scanBaseEp * multiplier };
}

export function weightReward(
  grams: number,
  isPro: boolean,
): { baseEp: number; multiplier: number; ep: number } {
  const blocks = Math.floor(grams / CONFIG.gramsPerBlock);
  const multiplier = isPro ? CONFIG.proMultiplier : 1;
  const baseEp = blocks * CONFIG.epPerBlock;
  return { baseEp, multiplier, ep: baseEp * multiplier };
}

/** Pro is active when flagged and not past an optional expiry. */
export function isProActive(user: { isPro?: unknown; proExpiry?: unknown } | null, nowMs: number): boolean {
  if (!user || user.isPro !== true) return false;
  const exp = Number(user.proExpiry ?? 0);
  return !(exp > 0) || exp > nowMs;
}

// ───────────────────────────── streak ─────────────────────────────

export interface StreakState {
  count: number;
  lastDay: string;
  history: string[];
}

export interface StreakResult {
  state: StreakState;
  alreadyDone: boolean;
  bonus: number;
}

export function nextStreak(prev: Partial<StreakState> | null, today: string): StreakResult {
  const state: StreakState = {
    count: Math.max(0, Math.floor(Number(prev?.count ?? 0))),
    lastDay: typeof prev?.lastDay === 'string' ? prev.lastDay : '',
    history: Array.isArray(prev?.history) ? prev!.history!.filter(isDayKey).slice(-7) : [],
  };

  // Same day (or a day in the future relative to `today`): nothing to do.
  if (state.lastDay && daysBetween(state.lastDay, today) <= 0) {
    return { state, alreadyDone: true, bonus: 0 };
  }

  const continues = state.lastDay === previousDay(today);
  const count = continues ? state.count + 1 : 1;
  const history = [...state.history, today].slice(-7);
  const bonus = count % CONFIG.streakBonusEveryDays === 0 ? CONFIG.streakBonusEp : 0;
  return { state: { count, lastDay: today, history }, alreadyDone: false, bonus };
}

/** A streak is only "alive" if the last check-in was today or yesterday. */
export function liveStreak(state: Partial<StreakState> | null, today: string): number {
  if (!state || typeof state.lastDay !== 'string') return 0;
  const alive = state.lastDay === today || state.lastDay === previousDay(today);
  return alive ? Math.max(0, Math.floor(Number(state.count ?? 0))) : 0;
}

// ───────────────────────────── missions ─────────────────────────────

export function isMissionId(v: unknown): v is MissionId {
  return typeof v === 'string' && Object.prototype.hasOwnProperty.call(MISSIONS, v);
}

export function missionComplete(id: MissionId, scansToday: number, streak: number): boolean {
  const m = MISSIONS[id];
  const progress = m.kind === 'scansToday' ? scansToday : streak;
  return progress >= m.goal;
}

// ───────────────────────────── money helpers ─────────────────────────────

export function percentFee(ep: number, percent: number): number {
  return Math.round((ep * percent) / 100);
}

export function isPositiveInt(v: unknown, min = 1, max = Number.MAX_SAFE_INTEGER): v is number {
  return typeof v === 'number' && Number.isInteger(v) && v >= min && v <= max;
}

// ───────────────────────────── text helpers ─────────────────────────────

// eslint-disable-next-line no-control-regex
const CONTROL = /[\u0000-\u001f\u007f-\u009f​-‏‪-‮⁦-⁩]/g;

export function cleanText(v: unknown, max: number): string {
  if (typeof v !== 'string') return '';
  return v.replace(CONTROL, '').replace(/\s+/g, ' ').trim().slice(0, max);
}

export function validName(name: string): boolean {
  return name.length >= CONFIG.nameMin && name.length <= CONFIG.nameMax;
}

export function validAvatar(v: unknown): v is string {
  return typeof v === 'string' && /^[a-z0-9_]{0,24}$/.test(v);
}

const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // no 0/O/1/I/L

export function randomCode(len: number, rng: () => number = Math.random): string {
  let out = '';
  for (let i = 0; i < len; i++) out += CODE_ALPHABET[Math.floor(rng() * CODE_ALPHABET.length)];
  return out;
}

export function normalizeCode(v: unknown): string {
  return typeof v === 'string' ? v.toUpperCase().replace(/[^A-Z0-9]/g, '') : '';
}

export function isUid(v: unknown): boolean {
  return typeof v === 'string' && /^[A-Za-z0-9]{20,40}$/.test(v);
}

/** Monday (yyyy-MM-dd, Asia/Baku) of the week containing `nowMs`. */
export function weekKey(nowMs: number): string {
  const dn = dayNumber(dayKey(nowMs));
  const monday = dn - ((dn + 3) % 7); // epoch day 0 was a Thursday
  return new Date(monday * 86_400_000).toISOString().slice(0, 10);
}
