import { CONFIG } from './lib/config';
import { dayKey, weekKey } from './lib/rules';
import type { PushSender } from './push';
import {
  runDailyReminder,
  runStreakRisk,
  runWeeklySummary,
  type ReminderEnv,
  type RunResult,
} from './services/reminders';
import type { Store } from './store';

interface Job {
  kind: string;
  /** Local (Asia/Baku) hour the job becomes due. */
  hour: number;
  /** It may still run this many hours later (covers a sleeping server). */
  windowHours: number;
  /** Limit to a weekday (1 = Monday … 7 = Sunday). */
  weekday?: number;
  run: (env: ReminderEnv) => Promise<RunResult>;
}

/** Removes old error reports (14 days) and weekly boards (keeps 4 weeks). */
export async function runMaintenance(env: ReminderEnv): Promise<RunResult> {
  let removed = 0;
  const errs = (await env.store.get<Record<string, any>>('errorLogs')) ?? {};
  for (const [id, e] of Object.entries(errs)) {
    if (Number(e?.ts) < env.now - 14 * 86_400_000) {
      await env.store.remove(`errorLogs/${id}`);
      removed++;
    }
  }
  const boards = (await env.store.get<Record<string, unknown>>('weeklyBoard')) ?? {};
  const cutoff = weekKey(env.now - 28 * 86_400_000);
  for (const wk of Object.keys(boards)) {
    if (wk < cutoff) {
      await env.store.remove(`weeklyBoard/${wk}`);
      removed++;
    }
  }
  const daily = (await env.store.get<Record<string, unknown>>('statsDaily')) ?? {};
  const dayCut = new Date(env.now - 120 * 86_400_000).toLocaleDateString('sv-SE', { timeZone: 'Asia/Baku' });
  for (const d of Object.keys(daily)) {
    if (d < dayCut) {
      await env.store.remove(`statsDaily/${d}`);
      removed++;
    }
  }
  return { considered: Object.keys(errs).length + Object.keys(boards).length + Object.keys(daily).length, sent: removed };
}

export const JOBS: Job[] = [
  { kind: 'maintenance', hour: 3, windowHours: 3, run: runMaintenance },
  { kind: 'dailyReminder', hour: 12, windowHours: 6, run: runDailyReminder },
  { kind: 'streakRisk', hour: 20, windowHours: 2, run: (e) => runStreakRisk(e) },
  { kind: 'weeklySummary', hour: 10, windowHours: 8, weekday: 1, run: runWeeklySummary },
];

function localHour(ms: number): number {
  const h = new Intl.DateTimeFormat('en-GB', {
    timeZone: CONFIG.timeZone,
    hour: 'numeric',
    hourCycle: 'h23',
  }).format(new Date(ms));
  return Number(h);
}

function localWeekday(ms: number): number {
  const w = new Intl.DateTimeFormat('en-US', { timeZone: CONFIG.timeZone, weekday: 'short' }).format(
    new Date(ms),
  );
  return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(w) + 1;
}

function due(job: Job, ms: number): boolean {
  const h = localHour(ms);
  if (h < job.hour || h >= job.hour + job.windowHours) return false;
  return job.weekday === undefined || localWeekday(ms) === job.weekday;
}

/**
 * Runs every job that is due and not yet done today. The "done" marker is
 * claimed atomically first, so a restart or two overlapping ticks can never
 * send the same reminder twice.
 */
export async function tick(
  deps: { store: Store; push: PushSender },
  ms: number,
  log: (m: string, e?: unknown) => void = () => {},
): Promise<Record<string, RunResult>> {
  const out: Record<string, RunResult> = {};
  const day = dayKey(ms);
  for (const job of JOBS) {
    if (!due(job, ms)) continue;
    const claim = await deps.store.transaction(`cron/${job.kind}/${day}`, (cur) =>
      cur === null || cur === undefined ? ms : undefined,
    );
    if (!claim.committed) continue;
    try {
      out[job.kind] = await job.run({ store: deps.store, push: deps.push, now: ms });
      log(`cron ${job.kind} ${day}: ${JSON.stringify(out[job.kind])}`);
    } catch (e) {
      // Release the marker so the next tick can retry within the window.
      await deps.store.remove(`cron/${job.kind}/${day}`);
      log(`cron ${job.kind} failed`, e);
    }
  }
  return out;
}

/** Checks once a minute. The timer never keeps the process alive on its own. */
export function startScheduler(
  deps: { store: Store; push: PushSender },
  log: (m: string, e?: unknown) => void = () => {},
): () => void {
  const timer = setInterval(() => {
    tick(deps, Date.now(), log).catch((e) => log('scheduler tick failed', e));
  }, 60_000);
  timer.unref?.();
  return () => clearInterval(timer);
}
