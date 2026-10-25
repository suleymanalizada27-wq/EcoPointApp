import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { applyReferral, claimChallenge, claimDailyCheckIn } from '../src/services/gamification';
import { dayKey, liveStreak, nextStreak, previousDay, resolveDay } from '../src/lib/rules';
import { ALICE, BOB, NOW, balanceOf, deps, expectReason, seedUser } from './helpers';

const DAY = 86_400_000;

describe('streak rules', () => {
  it('starts at 1, continues on consecutive days, resets after a gap', () => {
    let r = nextStreak(null, '2026-03-15');
    expect(r.state.count).toBe(1);
    r = nextStreak(r.state, '2026-03-16');
    expect(r.state.count).toBe(2);
    r = nextStreak(r.state, '2026-03-18');
    expect(r.state.count).toBe(1);
  });
  it('same day is a no-op and 7th day pays the bonus', () => {
    let st = nextStreak(null, '2026-03-01').state;
    for (let d = 2; d <= 6; d++) st = nextStreak(st, `2026-03-0${d}`).state;
    const seventh = nextStreak(st, '2026-03-07');
    expect(seventh.state.count).toBe(7);
    expect(seventh.bonus).toBe(50);
    const again = nextStreak(seventh.state, '2026-03-07');
    expect(again.alreadyDone).toBe(true);
    expect(again.bonus).toBe(0);
    expect(seventh.state.history).toHaveLength(7);
  });
  it('previousDay handles month and year boundaries', () => {
    expect(previousDay('2026-03-01')).toBe('2026-02-28');
    expect(previousDay('2026-01-01')).toBe('2025-12-31');
  });
  it('liveStreak is 0 once a day was missed', () => {
    const st = { count: 5, lastDay: '2026-03-10', history: [] };
    expect(liveStreak(st, '2026-03-10')).toBe(5);
    expect(liveStreak(st, '2026-03-11')).toBe(5);
    expect(liveStreak(st, '2026-03-12')).toBe(0);
  });
  it('resolveDay accepts ±1 day from the client, otherwise uses the server day', () => {
    const server = dayKey(NOW);
    expect(server).toBe('2026-03-15');
    expect(resolveDay('2026-03-14', NOW)).toBe('2026-03-14');
    expect(resolveDay('2026-03-16', NOW)).toBe('2026-03-16');
    expect(resolveDay('2030-01-01', NOW)).toBe(server);
    expect(resolveDay('garbage', NOW)).toBe(server);
  });
});

describe('claimDailyCheckIn', () => {
  it('records a check-in once per day', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    const a = await claimDailyCheckIn(deps(s), ALICE, '2026-03-15');
    expect(a).toEqual({ streak: 1, bonus: 0, alreadyDone: false });
    const b = await claimDailyCheckIn(deps(s, NOW + 1000), ALICE, '2026-03-15');
    expect(b).toMatchObject({ streak: 1, alreadyDone: true });
  });

  it('pays +50 EP exactly once on the 7th consecutive day', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    let last = { bonus: 0 };
    for (let i = 0; i < 7; i++) {
      last = await claimDailyCheckIn(deps(s, NOW + i * DAY), ALICE, undefined);
    }
    expect(last.bonus).toBe(50);
    expect(await balanceOf(s, ALICE)).toBe(50);
    await claimDailyCheckIn(deps(s, NOW + 6 * DAY + 1000), ALICE, undefined);
    expect(await balanceOf(s, ALICE)).toBe(50);
  });
});

describe('claimChallenge', () => {
  const day = '2026-03-15';
  it('refuses incomplete missions and unknown ids', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await s.set(`users/${ALICE}/daily/${day}`, { scans: 2, ep: 100 });
    await expectReason(claimChallenge(deps(s), ALICE, { challengeId: 'scan3', day }), 'invalid-input');
    await expectReason(claimChallenge(deps(s), ALICE, { challengeId: 'hack', day }), 'invalid-input');
    expect(await balanceOf(s, ALICE)).toBe(0);
  });

  it('pays once per day once the goal is reached', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await s.set(`users/${ALICE}/daily/${day}`, { scans: 3, ep: 150 });
    expect(await claimChallenge(deps(s), ALICE, { challengeId: 'scan3', day })).toEqual({ ep: 30 });
    await expectReason(claimChallenge(deps(s), ALICE, { challengeId: 'scan3', day }), 'duplicate');
    expect(await balanceOf(s, ALICE)).toBe(30);
    await expectReason(claimChallenge(deps(s), ALICE, { challengeId: 'scan5', day }), 'invalid-input');
  });

  it('streak mission needs a live 2-day streak', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await s.set(`users/${ALICE}/streak`, { count: 2, lastDay: day, history: [] });
    expect(await claimChallenge(deps(s), ALICE, { challengeId: 'streak2', day })).toEqual({ ep: 20 });
  });

  it('concurrent claims pay once', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await s.set(`users/${ALICE}/daily/${day}`, { scans: 5, ep: 250 });
    const r = await Promise.allSettled([
      claimChallenge(deps(s), ALICE, { challengeId: 'scan3', day }),
      claimChallenge(deps(s), ALICE, { challengeId: 'scan3', day }),
    ]);
    expect(r.filter((x) => x.status === 'fulfilled')).toHaveLength(1);
    expect(await balanceOf(s, ALICE)).toBe(30);
  });
});

describe('applyReferral', () => {
  async function setup() {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await seedUser(s, BOB, { referralCode: 'ABCD234' });
    await s.set('referralCodes/ABCD234', BOB);
    return s;
  }

  it('pays both sides once and records the referrer', async () => {
    const s = await setup();
    expect(await applyReferral(deps(s), ALICE, { code: 'abcd-234' })).toEqual({ bonus: 200 });
    expect(await balanceOf(s, ALICE)).toBe(200);
    expect(await balanceOf(s, BOB)).toBe(200);
    expect(await s.get(`users/${ALICE}/referredBy`)).toBe(BOB);
    await expectReason(applyReferral(deps(s), ALICE, { code: 'ABCD234' }), 'duplicate');
    expect(await balanceOf(s, BOB)).toBe(200);
  });

  it('rejects own code, unknown codes, old accounts', async () => {
    const s = await setup();
    await expectReason(applyReferral(deps(s), BOB, { code: 'ABCD234' }), 'invalid-input');
    await expectReason(applyReferral(deps(s), ALICE, { code: 'ZZZZ999' }), 'not-found');
    await expectReason(applyReferral(deps(s), ALICE, { code: '??' }), 'invalid-input');
    await expectReason(
      applyReferral(deps(s), ALICE, { code: 'ABCD234', accountCreatedAt: NOW - 30 * DAY }),
      'invalid-input',
    );
    expect(await balanceOf(s, ALICE)).toBe(0);
  });

  it('caps referrals per referrer and rolls back the claim', async () => {
    const s = await setup();
    await s.set(`users/${BOB}/referralCount`, 25);
    await expectReason(applyReferral(deps(s), ALICE, { code: 'ABCD234' }), 'invalid-input');
    expect(await s.get(`users/${ALICE}/referredBy`)).toBeNull();
    expect(await balanceOf(s, ALICE)).toBe(0);
  });
});
