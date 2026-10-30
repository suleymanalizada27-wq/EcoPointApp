import { WEEKLY_PRIZES } from '../lib/config';
import { weekKey } from '../lib/rules';
import { weeklyPrizeText } from '../lib/notify-text';
import { credit, notify } from './wallet';
import { userLang, type ReminderEnv, type RunResult } from './reminders';

/**
 * Monday: pays the top 3 EP earners of the PREVIOUS week. A per-user marker
 * (`weeklyPrizes/<week>/<uid>`) makes a retry or restart unable to pay twice.
 */
export async function runWeeklyPrizes(env: ReminderEnv): Promise<RunResult> {
  const { store, now } = env;
  const prev = weekKey(now - 7 * 86_400_000);
  const board = (await store.get<Record<string, any>>(`weeklyBoard/${prev}`)) ?? {};
  const ranked = Object.entries(board)
    .map(([uid, v]) => ({ uid, ep: Number(v?.ep) || 0 }))
    .filter((r) => r.ep > 0)
    .sort((a, b) => b.ep - a.ep || a.uid.localeCompare(b.uid))
    .slice(0, WEEKLY_PRIZES.length);

  let paid = 0;
  for (let i = 0; i < ranked.length; i++) {
    const { uid } = ranked[i];
    const prize = WEEKLY_PRIZES[i];
    const marker = await store.transaction(`weeklyPrizes/${prev}/${uid}`, (cur) =>
      cur === null || cur === undefined ? { rank: i + 1, ep: prize, ts: now } : undefined,
    );
    if (!marker.committed) continue;
    try {
      if (await store.get(`security/banned/${uid}`)) continue;
      await credit(store, uid, prize, { type: 'bonus', desc: `🏆 Weekly #${i + 1}` }, now);
      const text = weeklyPrizeText(await userLang(store, uid), i + 1, prize);
      await notify(store, uid, text.title, text.body, now, env.push);
      paid++;
    } catch {
      await store.remove(`weeklyPrizes/${prev}/${uid}`);
    }
  }
  return { considered: ranked.length, sent: paid };
}
