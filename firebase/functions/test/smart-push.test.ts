import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { MemoryPusher } from '../src/push';
import { runSmartPush, pickMessage } from '../src/services/smart-push';
import { registerPushToken } from '../src/services/push-tokens';
import { smartText } from '../src/lib/notify-text';
import { ALICE, seedUser } from './helpers';

const baku = (day: string, hh: number, mm = 0) =>
  Date.parse(`${day}T00:00:00Z`) + (hh - 4) * 3_600_000 + mm * 60_000;
const tok = 'tokenSMARTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

const facts = (over: Record<string, unknown> = {}) => ({
  name: 'Əli',
  today: '2026-03-15',
  streak: 0,
  checkedInToday: true,
  scansMonth: 0,
  claimedMonthly: new Set<string>(),
  daysLeftInMonth: 16,
  balance: 0,
  lastScanDay: '2026-03-14' as string | null,
  daysSinceScan: 1 as number | null,
  ...over,
});
const allow = { activity: true, offers: true };
const NOW = baku('2026-03-15', 12);

describe('pickMessage priority', () => {
  it('goal reached beats everything; claimed goals are skipped', () => {
    const p = pickMessage(facts({ scansMonth: 31, balance: 140, checkedInToday: false }), [{ id: 'a', name: 'Çay', ep: 150 }], allow, {}, 0, NOW);
    expect(p?.kind).toBe('monthlyReady');
    expect(p?.vars).toMatchObject({ goal: 30, ep: 300 });
    const q = pickMessage(facts({ scansMonth: 31, claimedMonthly: new Set(['m_scan30']) }), [], allow, {}, 0, NOW);
    expect(q?.kind).not.toBe('monthlyReady');
  });

  it('close to the monthly goal → exact scans left and days left', () => {
    const p = pickMessage(facts({ scansMonth: 26 }), [], allow, {}, 0, NOW);
    expect(p).toMatchObject({ kind: 'monthlyClose', vars: { left: 4, goal: 30, days: 16 }, route: '/challenges' });
  });

  it('reward within reach: picks the smallest real gap', () => {
    const rewards = [
      { id: 'a', name: 'Çay', ep: 150 },
      { id: 'b', name: 'Termos', ep: 600 },
    ];
    const p = pickMessage(facts({ balance: 120 }), rewards, allow, {}, 0, NOW);
    expect(p).toMatchObject({ kind: 'rewardClose', vars: { reward: 'Çay', gap: 30 }, route: '/rewards' });
    // too far away → nothing (checked in, no goals)
    expect(pickMessage(facts({ balance: 10 }), rewards, allow, {}, 0, NOW)).toBeNull();
  });

  it('comeback after 7+ days, at most 3 times, never when offers are off', () => {
    const f = facts({ daysSinceScan: 9, checkedInToday: true });
    expect(pickMessage(f, [], allow, {}, 0, NOW)?.kind).toBe('comeback');
    expect(pickMessage(f, [], allow, {}, 3, NOW)).toBeNull();
    expect(pickMessage(f, [], { activity: true, offers: false }, {}, 0, NOW)).toBeNull();
  });

  it('cool-down: the same kind is not repeated too soon', () => {
    const f = facts({ scansMonth: 26 });
    const recent = { monthlyClose: NOW - 86_400_000 };
    expect(pickMessage(f, [], allow, recent, 0, NOW)).toBeNull();
    const old = { monthlyClose: NOW - 4 * 86_400_000 };
    expect(pickMessage(f, [], allow, old, 0, NOW)?.kind).toBe('monthlyClose');
  });
});

describe('runSmartPush', () => {
  it('sends one real, personal message and records it', async () => {
    const store = new MemoryStore();
    const push = new MemoryPusher();
    await seedUser(store, ALICE, {
      name: 'Aysel Əliyeva',
      balance: 120,
      streak: { count: 3, lastDay: '2026-03-15', history: [] },
      daily: { '2026-03-14': { scans: 2, ep: 100 } },
    });
    await registerPushToken({ store, now: 1 }, ALICE, { token: tok, lang: 'en' });
    const r = await runSmartPush({ store, push, now: baku('2026-03-15', 12, 3) });
    expect(r.sent).toBe(1);
    expect(push.user[0]).toEqual({
      uid: ALICE,
      ...smartText('en', 'rewardClose', { name: 'Aysel', reward: 'Sugar-free Tea', gap: 30 }),
      route: '/rewards',
    });
    expect(await store.get(`pushLog/${ALICE}/lastDay`)).toBe('2026-03-15');
    // Same day again: nothing more.
    const again = await runSmartPush({ store, push, now: baku('2026-03-15', 13, 3) });
    expect(again.sent).toBe(0);
    expect(push.user).toHaveLength(1);
  });

  it('a brand-new account with no activity gets nothing', async () => {
    const store = new MemoryStore();
    const push = new MemoryPusher();
    await seedUser(store, ALICE, {});
    await registerPushToken({ store, now: 1 }, ALICE, { token: tok });
    expect((await runSmartPush({ store, push, now: baku('2026-03-15', 12, 3) })).sent).toBe(0);
  });
});
