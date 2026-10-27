import { beforeEach, describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { MemoryPusher } from '../src/push';
import { tick } from '../src/scheduler';
import { registerPushToken, unregisterPushToken } from '../src/services/push-tokens';
import { dailyReminderText, streakRiskText, weeklySummaryText } from '../src/lib/notify-text';
import { ALICE, BOB, seedUser } from './helpers';

const CAROL = 'carolCarolCarolCarol03';
const tok = (n: string) => `token${n}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA`;

// Asia/Baku is UTC+4. 2026-03-15 is a Sunday, 2026-03-16 a Monday.
const baku = (day: string, hh: number, mm = 0) =>
  Date.parse(`${day}T00:00:00Z`) + (hh - 4) * 3_600_000 + mm * 60_000;

async function setup(store: MemoryStore, uid: string, lang: string, extra: Record<string, unknown> = {}) {
  await seedUser(store, uid, extra);
  await registerPushToken({ store, now: 1 }, uid, { token: tok(uid.slice(0, 4)), lang });
}

describe('scheduled reminders', () => {
  let store: MemoryStore;
  let push: MemoryPusher;
  beforeEach(() => {
    store = new MemoryStore();
    push = new MemoryPusher();
  });

  it('daily reminder: only people who have not checked in, in their language, honouring prefs', async () => {
    await setup(store, ALICE, 'ru', { streak: { count: 4, lastDay: '2026-03-14', history: [] } });
    await setup(store, BOB, 'az', { streak: { count: 2, lastDay: '2026-03-15', history: [] } });
    await setup(store, CAROL, 'en', { prefs: { notifyActivity: false } });

    const r = await tick({ store, push }, baku('2026-03-15', 12, 5));
    expect(r.dailyReminder).toEqual({ considered: 3, sent: 1 });
    expect(push.user).toEqual([{ uid: ALICE, ...dailyReminderText('ru', 4) }]);
  });

  it('runs at most once per day, even if ticked again or restarted', async () => {
    await setup(store, ALICE, 'az');
    await tick({ store, push }, baku('2026-03-15', 12, 5));
    await tick({ store, push }, baku('2026-03-15', 12, 6));
    await tick({ store, push }, baku('2026-03-15', 15, 0));
    expect(push.user).toHaveLength(1);
    // …and again the next day.
    await tick({ store, push }, baku('2026-03-16', 12, 1));
    expect(push.user).toHaveLength(2);
  });

  it('does not run before its hour or after its window; catches up if the server slept', async () => {
    await setup(store, ALICE, 'az');
    expect(await tick({ store, push }, baku('2026-03-15', 9, 0))).toEqual({});
    expect(await tick({ store, push }, baku('2026-03-15', 18, 30))).toEqual({});
    expect(push.user).toHaveLength(0);
    // Woke up at 15:40 → still inside the 12:00–18:00 window.
    const r = await tick({ store, push }, baku('2026-03-15', 15, 40));
    expect(r.dailyReminder?.sent).toBe(1);
  });

  it('streak risk: only a live streak of 3+ days that was not continued today', async () => {
    await setup(store, ALICE, 'tr', { streak: { count: 5, lastDay: '2026-03-14', history: [] } });
    await setup(store, BOB, 'az', { streak: { count: 2, lastDay: '2026-03-14', history: [] } });
    await setup(store, CAROL, 'en', { streak: { count: 9, lastDay: '2026-03-15', history: [] } });
    const r = await tick({ store, push }, baku('2026-03-15', 20, 10));
    expect(r.streakRisk).toEqual({ considered: 3, sent: 1 });
    expect(push.user).toEqual([{ uid: ALICE, ...streakRiskText('tr', 5) }]);
  });

  it('weekly summary: Mondays only, real totals of the previous 7 days, skipped when nothing earned', async () => {
    const daily: Record<string, unknown> = {};
    for (let d = 9; d <= 15; d++) daily[`2026-03-${String(d).padStart(2, '0')}`] = { ep: 20, scans: 2 };
    daily['2026-03-16'] = { ep: 999, scans: 99 }; // today is not part of "last week"
    await setup(store, ALICE, 'en', { daily });
    await setup(store, BOB, 'az');

    // Sunday: not due.
    expect(await tick({ store, push }, baku('2026-03-15', 10, 30))).toMatchObject({});
    expect(push.user.find((m) => m.title.includes('summary'))).toBeUndefined();

    const r = await tick({ store, push }, baku('2026-03-16', 10, 30));
    expect(r.weeklySummary).toEqual({ considered: 2, sent: 1 });
    expect(push.user).toContainEqual({ uid: ALICE, ...weeklySummaryText('en', 140, 14) });
  });

  it('a user without devices is never contacted; unregistering removes the index', async () => {
    await seedUser(store, ALICE, {});
    await tick({ store, push }, baku('2026-03-15', 12, 5));
    expect(push.user).toHaveLength(0);

    await registerPushToken({ store, now: 1 }, ALICE, { token: tok('one1') });
    expect(await store.get(`pushUsers/${ALICE}`)).toBe(true);
    await unregisterPushToken({ store, now: 2 }, ALICE, { token: tok('one1') });
    expect(await store.get(`pushUsers/${ALICE}`)).toBeNull();
  });

  it('registration keeps the device language, defaulting to az', async () => {
    await registerPushToken({ store, now: 1 }, ALICE, { token: tok('aaa1'), lang: 'tr' });
    await registerPushToken({ store, now: 2 }, BOB, { token: tok('bbb2'), lang: 'xx' });
    const a = Object.values((await store.get<Record<string, any>>(`pushTokens/${ALICE}`))!)[0];
    const b = Object.values((await store.get<Record<string, any>>(`pushTokens/${BOB}`))!)[0];
    expect(a.lang).toBe('tr');
    expect(b.lang).toBe('az');
  });
});
