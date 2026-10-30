import type { Store } from '../store';

const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);

/**
 * Records a suspicious-activity hint for the admin list (`suspicious/<uid>`).
 * Hints are signals for a human, never an automatic ban. Best effort.
 */
export async function flagUser(store: Store, uid: string, reason: string, now: number): Promise<void> {
  try {
    const safe = reason.replace(/[.#$/[\]]/g, '_').slice(0, 40);
    await store.transaction(`suspicious/${uid}`, (cur) => {
      const c = (cur ?? {}) as { total?: number; reasons?: Record<string, number> };
      const reasons = { ...(c.reasons ?? {}) };
      reasons[safe] = num(reasons[safe]) + 1;
      return { last: now, total: num(c.total) + 1, reasons };
    });
  } catch {
    /* ignore */
  }
}

/** Scans in one day above this are worth a human look (the hourly cap is 10). */
export const MANY_SCANS_PER_DAY = 25;
