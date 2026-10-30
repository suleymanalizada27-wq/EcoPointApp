import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { MemoryPusher } from '../src/push';
import { claimMonthly } from '../src/services/gamification';
import { reserveDaily } from '../src/services/wallet';
import { runWeeklyPrizes } from '../src/services/weekly-prizes';
import { tick } from '../src/scheduler';
import { weekKey } from '../src/lib/rules';
import { ALICE, BOB, NOW, balanceOf, deps, expectReason, seedUser } from './helpers';

const CAROL = 'carolCarolCarolCarol03';
const DAN = 'danDanDanDanDanDanDan04';

describe('monthly goals', () => {
  it('counts scans per month and pays each goal once', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    for (let i = 0; i < 29; i++) await reserveDaily(s, ALICE, '2026-03-15', { ep: 1, scans: 1 });
    await expectReason(claimMonthly(deps(s), ALICE, { challengeId: 'm_scan30' }), 'invalid-input');
    await reserveDaily(s, ALICE, '2026-03-15', { ep: 1, scans: 1 });
    expect(await claimMonthly(deps(s), ALICE, { challengeId: 'm_scan30' })).toEqual({ ep: 300 });
    await expectReason(claimMonthly(deps(s), ALICE, { challengeId: 'm_scan30' }), 'duplicate');
    await expectReason(claimMonthly(deps(s), ALICE, { challengeId: 'bogus' }), 'invalid-input');
    expect(await balanceOf(s, ALICE)).toBe(300);
  });

  it('is claimable again next month', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await s.set(`users/${ALICE}/monthly/2026-03/scans`, 30);
    await s.set(`users/${ALICE}/monthly/2026-04/scans`, 30);
    await claimMonthly(deps(s), ALICE, { challengeId: 'm_scan30' });
    const april = Date.UTC(2026, 3, 10, 8);
    await claimMonthly(deps(s, april), ALICE, { challengeId: 'm_scan30' });
    expect(await balanceOf(s, ALICE)).toBe(600);
  });
});

describe('weekly prizes', () => {
  async function seedBoard(s: MemoryStore, now: number) {
    const prev = weekKey(now - 7 * 86_400_000);
    for (const [uid, ep] of [[ALICE, 500], [BOB, 300], [CAROL, 200], [DAN, 100]] as const) {
      await seedUser(s, uid);
      await s.set(`weeklyBoard/${prev}/${uid}`, { ep, name: uid });
    }
  }

  it('pays the top 3 of last week once, with a notification', async () => {
    const s = new MemoryStore();
    const push = new MemoryPusher();
    await seedBoard(s, NOW);
    const r = await runWeeklyPrizes({ store: s, push, now: NOW });
    expect(r.sent).toBe(3);
    expect(await balanceOf(s, ALICE)).toBe(200);
    expect(await balanceOf(s, BOB)).toBe(100);
    expect(await balanceOf(s, CAROL)).toBe(50);
    expect(await balanceOf(s, DAN)).toBe(0);
    await runWeeklyPrizes({ store: s, push, now: NOW });
    expect(await balanceOf(s, ALICE)).toBe(200);
    expect(push.user.length).toBe(3);
  });

  it('runs from the scheduler on Monday morning only', async () => {
    const s = new MemoryStore();
    const push = new MemoryPusher();
    const monday = Date.UTC(2026, 2, 16, 3, 0); // 07:00 Baku, Monday
    await seedBoard(s, monday);
    const sunday = Date.UTC(2026, 2, 15, 3, 0);
    expect((await tick({ store: s, push }, sunday)).weeklyPrizes).toBeUndefined();
    expect((await tick({ store: s, push }, monday)).weeklyPrizes?.sent).toBe(3);
  });
});
