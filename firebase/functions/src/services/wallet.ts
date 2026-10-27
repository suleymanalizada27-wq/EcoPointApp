import { CONFIG } from '../lib/config';
import { Errors } from '../errors';
import { weekKey } from '../lib/rules';
import type { PushSender } from '../push';
import type { Store } from '../store';
import { bumpStat } from './stats';

export type TxType = 'earn' | 'received' | 'sent' | 'purchase' | 'weight' | 'bonus' | 'other';

export interface TxMeta {
  type: TxType;
  desc: string;
  status?: 'completed' | 'pending' | 'failed';
}

const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);

export async function increment(store: Store, path: string, by: number): Promise<number> {
  const res = await store.transaction(path, (cur) => num(cur) + by);
  return num(res.value);
}

async function writeTx(
  store: Store,
  uid: string,
  signed: number,
  meta: TxMeta,
  now: number,
): Promise<string> {
  const abs = Math.abs(signed);
  return store.push(`users/${uid}/transactions`, {
    type: meta.type,
    amount: `${signed < 0 ? '-' : '+'}${abs}`,
    rawAmount: abs,
    desc: meta.desc,
    ts: now,
    status: meta.status ?? 'completed',
  });
}

async function syncLeaderboard(store: Store, uid: string, balance: number): Promise<void> {
  await store.update(`leaderboard/${uid}`, { ep: balance });
}

/** Public weekly ranking: EP *earned* this week (not balance). */
async function bumpWeekly(store: Store, uid: string, amount: number, now: number): Promise<void> {
  try {
    const path = `weeklyBoard/${weekKey(now)}/${uid}`;
    await increment(store, `${path}/ep`, amount);
    const lb = await store.get<any>(`leaderboard/${uid}`);
    await store.update(path, {
      name: typeof lb?.name === 'string' ? lb.name : '—',
      photoURL: typeof lb?.photoURL === 'string' ? lb.photoURL : '',
      avatar: typeof lb?.avatar === 'string' ? lb.avatar : '',
    });
  } catch {
    /* the ranking must never block an EP credit */
  }
}

/**
 * Adds EP. `earned` marks recycling income, which feeds the lifetime
 * `stats/earned` counter (levels, achievements).
 */
export async function credit(
  store: Store,
  uid: string,
  amount: number,
  meta: TxMeta,
  now: number,
  opts: { earned?: boolean } = {},
): Promise<number> {
  if (!Number.isInteger(amount) || amount <= 0) throw Errors.invalid('Invalid amount');
  const balance = await increment(store, `users/${uid}/balance`, amount);
  if (opts.earned) {
    await increment(store, `users/${uid}/stats/earned`, amount);
    await bumpWeekly(store, uid, amount, now);
    await bumpStat(store, now, 'earnedEp', amount);
    await bumpStat(store, now, 'earns', 1);
  }
  await writeTx(store, uid, amount, meta, now);
  await syncLeaderboard(store, uid, balance);
  return balance;
}

/** Removes EP atomically; throws `insufficient-balance` if it would go below 0. */
export async function debit(
  store: Store,
  uid: string,
  amount: number,
  meta: TxMeta,
  now: number,
): Promise<number> {
  if (!Number.isInteger(amount) || amount <= 0) throw Errors.invalid('Invalid amount');
  let applied = false;
  const res = await store.transaction(`users/${uid}/balance`, (cur) => {
    // `null` is the first guess of a cold cache: return a no-op value so the
    // SDK re-runs us with the real server value.
    if (cur === null || cur === undefined) {
      applied = false;
      return 0;
    }
    const bal = num(cur);
    if (bal < amount) {
      applied = false;
      return undefined;
    }
    applied = true;
    return bal - amount;
  });
  if (!res.committed || !applied) throw Errors.insufficient();
  const balance = num(res.value);
  await writeTx(store, uid, -amount, meta, now);
  await syncLeaderboard(store, uid, balance);
  return balance;
}

/** Customer-visible, server-written notification. */
export async function notify(
  store: Store,
  uid: string,
  title: string,
  body: string,
  now: number,
  push?: PushSender,
): Promise<void> {
  await store.push(`users/${uid}/notifications`, { title, body, ts: now });
  if (!push) return;
  // Best-effort device push; honours the user's "activity" preference.
  try {
    const pref = await store.get<boolean>(`users/${uid}/prefs/notifyActivity`);
    if (pref !== false) await push.toUser(uid, { title, body });
  } catch {
    /* a push failure must never affect the operation that triggered it */
  }
}

// ───────────────────────── guards ─────────────────────────

const REQUEST_ID = /^[A-Za-z0-9_-]{8,64}$/;

/**
 * Makes a mutating call idempotent: the same `requestId` returns the stored
 * result instead of paying / charging twice (client retries, flaky mobile
 * networks). A failed run releases the id so the user can retry.
 */
export async function once<T>(
  store: Store,
  uid: string,
  requestId: unknown,
  now: number,
  run: () => Promise<T>,
): Promise<T> {
  if (typeof requestId !== 'string' || !REQUEST_ID.test(requestId)) {
    throw Errors.invalid('requestId required');
  }
  const path = `idempotency/${uid}/${requestId}`;
  const claim = await store.transaction(path, (cur) =>
    cur === null || cur === undefined ? { ts: now, state: 'pending' } : undefined,
  );
  if (!claim.committed) {
    const existing = await store.get<any>(path);
    if (existing?.state === 'done') return existing.result as T;
    throw Errors.duplicate('Request already in progress');
  }
  try {
    const result = await run();
    await store.set(path, { ts: now, state: 'done', result });
    return result;
  } catch (e) {
    await store.remove(path);
    throw e;
  }
}

export async function rateLimit(
  store: Store,
  key: string,
  now: number,
  opts: { windowMs: number; max: number; minIntervalMs?: number },
): Promise<void> {
  let blocked = false;
  await store.transaction(`rate/${key}`, (cur) => {
    blocked = false;
    const c = (cur ?? {}) as { start?: number; count?: number; last?: number };
    let start = num(c.start) || now;
    let count = num(c.count);
    const last = num(c.last);
    if (now - start >= opts.windowMs) {
      start = now;
      count = 0;
    }
    if (opts.minIntervalMs && last && now - last < opts.minIntervalMs) {
      blocked = true;
      return undefined;
    }
    if (count >= opts.max) {
      blocked = true;
      return undefined;
    }
    return { start, count: count + 1, last: now };
  });
  if (blocked) throw Errors.rateLimited();
}

/** Reserves part of the per-day earning allowance. */
export async function reserveDaily(
  store: Store,
  uid: string,
  day: string,
  add: { ep: number; scans?: number; grams?: number },
): Promise<void> {
  let blocked = false;
  await store.transaction(`users/${uid}/daily/${day}`, (cur) => {
    blocked = false;
    const c = (cur ?? {}) as { ep?: number; scans?: number; grams?: number };
    const ep = num(c.ep) + add.ep;
    const grams = num(c.grams) + (add.grams ?? 0);
    if (ep > CONFIG.maxEpPerDay || grams > CONFIG.maxWeightPerDayG) {
      blocked = true;
      return undefined;
    }
    return { ep, scans: num(c.scans) + (add.scans ?? 0), grams };
  });
  if (blocked) throw Errors.dailyLimit();
}

export async function assertNotBanned(store: Store, uid: string): Promise<void> {
  const banned = await store.get(`security/banned/${uid}`);
  if (banned) throw Errors.banned();
}
