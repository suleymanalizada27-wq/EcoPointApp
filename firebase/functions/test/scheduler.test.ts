import { beforeEach, describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { MemoryPusher } from '../src/push';
import { tick } from '../src/scheduler';
import { ackPush, registerPushToken, unregisterPushToken } from '../src/services/push-tokens';
import { smartText, streakRiskText, weeklySummaryText } from '../src/lib/notify-text';
import { allowedHours, dailyCap, sendHourFor, slotHours } from '../src/services/smart-push';
import { weekKey } from '../src/lib/rules';
import { adminPushStats, adminSetPushEnabled } from '../src/services/admin';
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

  it('smart push v2: personal daily message, tip for the checked-in, nothing for opted-out', async () => {
    await setup(store, ALICE, 'ru', { streak: { count: 4, lastDay: '2026-03-14', history: [] } });
    await setup(store, BOB, 'az', { streak: { count: 2, lastDay: '2026-03-15', history: [] } });
    await setup(store, CAROL, 'en', { prefs: { notifyActivity: false, notifyOffers: false } });

    const r = await tick({ store, push }, baku('2026-03-15', 12, 5));
    expect(r.smartPush).toEqual({ considered: 3, sent: 2 });
    const alice = push.user.find((m) => m.uid === ALICE);
    expect(alice).toEqual({
      uid: ALICE,
      ...smartText('ru', 'daily', { name: 'alice', streak: 4 }),
      route: '/home',
      kind: 'daily',
      id: '2026-03-15_12',
    });
    // Bob's 2-day streak already completes the "streak2" mission: claim it.
    expect(push.user.find((m) => m.uid === BOB)?.kind).toBe('mission');
    expect(push.user.find((m) => m.uid === CAROL)).toBeUndefined();
  });

  it('never exceeds the daily cap (4 for a person who never taps) and never sends twice in one slot', async () => {
    await setup(store, ALICE, 'az', { streak: { count: 2, lastDay: '2026-03-14', history: [] } });
    for (let h = 9; h <= 20; h++) {
      await tick({ store, push }, baku('2026-03-15', h, 5));
      await tick({ store, push }, baku('2026-03-15', h, 6));
    }
    // Slots 9, 12, 15, 18: daily, finished mission, then two tips.
    expect(push.user.map((m) => m.kind)).toEqual(['daily', 'mission', 'tip', 'tip']);
    expect(push.user.map((m) => m.id)).toEqual(['2026-03-15_09', '2026-03-15_12', '2026-03-15_15', '2026-03-15_18']);
  });

  it('sends only inside 09:00–21:00 local time', async () => {
    await setup(store, ALICE, 'az', { streak: { count: 2, lastDay: '2026-03-14', history: [] } });
    expect(await tick({ store, push }, baku('2026-03-15', 7, 0))).toMatchObject({ smartPush: { sent: 0 } });
    expect(await tick({ store, push }, baku('2026-03-15', 23, 30))).toMatchObject({ smartPush: { sent: 0 } });
    expect(push.user).toHaveLength(0);
  });

  it('slot maths: cap 4..9 spread evenly; engagement raises the cap; inactive users get 2', () => {
    expect(slotHours(4)).toEqual([9, 12, 15, 18]);
    expect(slotHours(9)).toEqual([9, 10, 11, 13, 14, 16, 17, 19, 20]);
    expect(dailyCap(0, 1, undefined)).toBe(4);
    expect(dailyCap(5, 1, undefined)).toBe(9);
    expect(dailyCap(20, 1, 'normal')).toBe(9);
    expect(dailyCap(5, 1, 'low')).toBe(2);
    expect(dailyCap(0, 1, 'high')).toBe(9);
    expect(allowedHours(undefined, undefined)).toEqual([9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]);
    expect(allowedHours(20, 12)).toContain(12);
    expect(allowedHours(20, 12)).not.toContain(23);
    expect(slotHours(3, allowedHours(20, 12))).toHaveLength(3);
    expect(dailyCap(5, 9, undefined)).toBe(2);
    expect(sendHourFor({ h18: 5, h9: 1 })).toBe(17);
  });

  it('uses the device time zone: the first slot is 09:00 on the device clock (Istanbul = 10:00 Baku)', async () => {
    await setup(store, ALICE, 'tr', { streak: { count: 2, lastDay: '2026-03-14', history: [] } });
    await registerPushToken({ store, now: 5 }, ALICE, { token: 'tokenTZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', lang: 'tr', tz: 180 });
    await tick({ store, push }, baku('2026-03-15', 10, 5)); // 06:05 UTC = 09:05 Istanbul
    expect(push.user[0]?.id).toBe('2026-03-15_09');
  });

  it('opening pushes raises the cap for the next days', async () => {
    await setup(store, ALICE, 'az', { streak: { count: 2, lastDay: '2026-03-14', history: [] } });
    for (const d of ['10', '11', '12', '13', '14']) {
      await ackPush({ store, now: baku('2026-03-15', 8) }, ALICE, { id: `2026-03-${d}_12`, kind: 'tip' });
    }
    for (let h = 9; h <= 20; h++) await tick({ store, push }, baku('2026-03-15', h, 5));
    expect(push.user).toHaveLength(8); // cap 9: daily, mission, 6 tips
    expect(await store.get(`pushLog/${ALICE}/openKinds/tip`)).toBe(5);
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

  // ───────────── v2: frequency, quiet hours, switches, new kinds, stats ─────────────

  const day = '2026-03-15';
  const runDay = async (d = day) => {
    for (let h = 0; h <= 23; h++) await tick({ store, push }, baku(d, h, 5));
  };

  it('"high" sends up to 9 a day, "low" only 2', async () => {
    await setup(store, ALICE, 'en', { streak: { count: 2, lastDay: '2026-03-14', history: [] }, prefs: { notifyFreq: 'high' } });
    await runDay();
    expect(push.user.length).toBeGreaterThanOrEqual(8);
    expect(push.user.length).toBeLessThanOrEqual(9);

    const s2 = new MemoryStore();
    const p2 = new MemoryPusher();
    await setup(s2, BOB, 'en', { streak: { count: 2, lastDay: '2026-03-14', history: [] }, prefs: { notifyFreq: 'low' } });
    for (let h = 0; h <= 23; h++) await tick({ store: s2, push: p2 }, baku(day, h, 5));
    expect(p2.user).toHaveLength(2);
  });

  it('quiet hours: custom range moves the window; nothing is sent inside it', async () => {
    await setup(store, ALICE, 'en', {
      streak: { count: 2, lastDay: '2026-03-14', history: [] },
      prefs: { quietFrom: 13, quietTo: 18 },
    });
    await runDay();
    const hours = push.user.map((m) => Number(m.id!.slice(11)));
    expect(hours.length).toBeGreaterThan(0);
    for (const h of hours) expect(h < 13 || h >= 18).toBe(true);
  });

  it('per-type switches: tips off, missions off', async () => {
    await setup(store, ALICE, 'en', {
      streak: { count: 2, lastDay: '2026-03-14', history: [] },
      prefs: { notifyTips: false, notifyMissions: false },
    });
    await runDay();
    expect(push.user.every((m) => m.kind === 'daily')).toBe(true);
    expect(push.user).toHaveLength(1);
  });

  it('mission close, leaderboard and streak milestone messages come from real data', async () => {
    await seedUser(store, ALICE, { streak: { count: 1, lastDay: day, history: [] } });
    await registerPushToken({ store, now: 1 }, ALICE, { token: tok('ALIC'), lang: 'en' });
    await store.set(`users/${ALICE}/daily/${day}`, { scans: 2, ep: 30 });
    await store.set(`users/${ALICE}/daily/2026-03-14`, { scans: 1, ep: 10 });
    await tick({ store, push }, baku(day, 12, 5));
    const first = push.user.find((m) => m.uid === ALICE)!;
    expect(first.kind).toBe('mission'); // 2 of 3 scans, 30 EP waiting
    expect(first.body).toContain('1 more scan');

    // leaderboard: Alice 4th, 30 EP behind the 3rd
    await seedUser(store, BOB, {});
    const wk = weekKey(baku(day, 12));
    await store.set(`weeklyBoard/${wk}`, {
      ['u1']: { ep: 500 }, ['u2']: { ep: 400 }, ['u3']: { ep: 130 }, [ALICE]: { ep: 100 },
    });
    await tick({ store, push }, baku(day, 15, 5));
    expect(push.user.filter((m) => m.uid === ALICE).map((m) => m.kind)).toContain('leaderboard');
    expect(push.user.find((m) => m.kind === 'leaderboard')!.body).toContain('31 EP');
  });

  it('streak milestone fires on 7/14/30… once', async () => {
    await setup(store, ALICE, 'en', { streak: { count: 7, lastDay: day, history: [] } });
    await tick({ store, push }, baku(day, 12, 5));
    expect(push.user[0].kind).toBe('milestone');
    expect(push.user[0].body).toContain('7-day');
  });

  it('every smart push lands in the in-app inbox, is counted, and tapping counts as opened', async () => {
    await setup(store, ALICE, 'az', { streak: { count: 2, lastDay: '2026-03-14', history: [] } });
    await tick({ store, push }, baku(day, 12, 5));
    const inbox = Object.values((await store.get<Record<string, any>>(`users/${ALICE}/notifications`)) ?? {});
    expect(inbox).toHaveLength(1);
    expect(inbox[0]).toMatchObject({ kind: 'daily' });
    await ackPush({ store, now: baku(day, 12, 30) }, ALICE, { id: push.user[0].id, kind: 'daily' });
    const stats = await adminPushStats({ store, now: baku(day, 13) }, {});
    expect(stats.rows.find((r) => r.kind === 'daily')).toMatchObject({ sent: 1, opened: 1, rate: 1 });
  });

  it('admin master switch stops automatic pushes', async () => {
    await setup(store, ALICE, 'az', { streak: { count: 2, lastDay: '2026-03-14', history: [] } });
    expect(await adminSetPushEnabled({ store, now: 0 }, { enabled: false })).toEqual({ disabled: true });
    await tick({ store, push }, baku(day, 12, 5));
    expect(push.user).toHaveLength(0);
    await adminSetPushEnabled({ store, now: 0 }, { enabled: true });
    await tick({ store, push }, baku(day, 15, 5));
    expect(push.user.length).toBe(1);
    expect((await adminPushStats({ store, now: baku(day, 13) }, { days: 3 })).disabled).toBe(false);
  });
});
