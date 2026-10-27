import { beforeEach, describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { isAdminToken, parseAdminEmails } from '../src/admin-access';
import {
  adminDeleteReward,
  adminErrorLogs,
  adminGetUser,
  adminListTransport,
  adminLookupCoupon,
  adminOverview,
  adminRedeemCoupon,
  adminSearchUsers,
  adminSetBan,
  adminSetPro,
  adminUpsertDevice,
  adminUpsertReward,
} from '../src/services/admin';
import { reportError } from '../src/services/errors-report';
import { createCoupon, purchaseReward } from '../src/services/market';
import { claimDailyCheckIn } from '../src/services/gamification';
import { credit } from '../src/services/wallet';
import { runMaintenance, tick } from '../src/scheduler';
import { MemoryPusher } from '../src/push';
import { weekKey } from '../src/lib/rules';
import { ALICE, BOB, NOW, balanceOf, deps, expectReason, seedUser } from './helpers';

const ADMIN = 'adminAdminAdminAdmin1';

describe('admin access', () => {
  const allowed = parseAdminEmails(' Boss@Example.com , other@x.az,notanemail');
  it('parses and normalises the allow-list', () => {
    expect([...allowed].sort()).toEqual(['boss@example.com', 'other@x.az']);
  });
  it('requires a VERIFIED e-mail on the list (or the custom claim)', () => {
    expect(isAdminToken({ email: 'boss@example.com', email_verified: true }, allowed)).toBe(true);
    expect(isAdminToken({ email: 'BOSS@example.com', email_verified: true }, allowed)).toBe(true);
    expect(isAdminToken({ email: 'boss@example.com', email_verified: false }, allowed)).toBe(false);
    expect(isAdminToken({ email: 'boss@example.com' }, allowed)).toBe(false);
    expect(isAdminToken({ email: 'eve@example.com', email_verified: true }, allowed)).toBe(false);
    expect(isAdminToken({ admin: true }, allowed)).toBe(true);
    expect(isAdminToken({}, allowed)).toBe(false);
  });
});

describe('admin console services', () => {
  let s: MemoryStore;
  beforeEach(async () => {
    s = new MemoryStore();
    await seedUser(s, ALICE, { name: 'Alice', balance: 500, email: 'a@x.az', createdAt: NOW });
    await seedUser(s, BOB, { name: 'Bob', balance: 100 });
  });

  it('overview counts users, EP, bins, pending transport and recent errors', async () => {
    await s.set('devices/bin-01', { name: 'x' });
    await s.push('transportRequests', { status: 'pending', uid: ALICE, card: '1', ep: 1, ts: NOW });
    await s.push('transportRequests', { status: 'completed', uid: ALICE, card: '1', ep: 1, ts: NOW });
    await s.push('errorLogs', { ts: NOW - 1000, message: 'x' });
    await s.push('errorLogs', { ts: NOW - 3 * 86_400_000, message: 'old' });
    expect(await adminOverview(deps(s))).toMatchObject({
      users: 2,
      totalEp: 600,
      bins: 1,
      pendingTransport: 1,
      errors24h: 1,
    });
  });

  it('searches users by name prefix / uid and loads details', async () => {
    expect((await adminSearchUsers(deps(s), 'ali')).users.map((u) => u.uid)).toEqual([ALICE]);
    expect((await adminSearchUsers(deps(s), ALICE)).users).toHaveLength(1);
    expect((await adminSearchUsers(deps(s), 'a')).users).toEqual([]);
    expect(await adminGetUser(deps(s), ALICE)).toMatchObject({ name: 'Alice', balance: 500, banned: false });
    await expectReason(adminGetUser(deps(s), 'nope'), 'invalid-input');
  });

  it('ban blocks spending and unban restores it; admin cannot ban self', async () => {
    await adminSetBan(deps(s), ADMIN, { uid: BOB, banned: true, reason: 'fraud' });
    expect((await adminGetUser(deps(s), BOB)).banned).toBe(true);
    await expectReason(
      purchaseReward(deps(s), BOB, { rewardId: 'p1', requestId: 'req-ban-0001' }),
      'banned',
    );
    await adminSetBan(deps(s), ADMIN, { uid: BOB, banned: false, reason: '' });
    expect((await adminGetUser(deps(s), BOB)).banned).toBe(false);
    await expectReason(adminSetBan(deps(s), ADMIN, { uid: ADMIN, banned: true, reason: '' }), 'invalid-input');
  });

  it('sets and clears Pro with an expiry', async () => {
    const r = await adminSetPro(deps(s), ADMIN, { uid: ALICE, days: 30 });
    expect(r.isPro).toBe(true);
    expect(r.proExpiry).toBe(NOW + 30 * 86_400_000);
    expect((await adminGetUser(deps(s), ALICE)).isPro).toBe(true);
    expect((await adminSetPro(deps(s), ADMIN, { uid: ALICE, days: 0 })).isPro).toBe(false);
    await expectReason(adminSetPro(deps(s), ADMIN, { uid: ALICE, days: -1 }), 'invalid-input');
  });

  it('manages rewards: validation, upsert (purchasable afterwards), delete', async () => {
    await expectReason(adminUpsertReward(deps(s), ADMIN, { id: 'bad id', ep: 10, name: { az: 'x' } }), 'invalid-input');
    await expectReason(adminUpsertReward(deps(s), ADMIN, { id: 'n1', ep: 0, name: { az: 'x' } }), 'invalid-input');
    await expectReason(adminUpsertReward(deps(s), ADMIN, { id: 'n1', ep: 10, name: {} }), 'invalid-input');
    await adminUpsertReward(deps(s), ADMIN, { id: 'n1', ep: 120, name: { az: 'Yeni' }, cat: 'eco', stock: 2 });
    expect(await s.get('rewards/n1')).toMatchObject({ ep: 120, cat: 'eco', stock: 2, active: true });
    expect((await s.get<any>('rewards/n1')).name.en).toBe('Yeni'); // falls back to az
    await purchaseReward(deps(s), ALICE, { rewardId: 'n1', requestId: 'req-rwd-0001' });
    expect(await balanceOf(s, ALICE)).toBe(380);
    await adminDeleteReward(deps(s), ADMIN, 'n1');
    expect(await s.get('rewards/n1')).toBeNull();
  });

  it('upserts a bin without touching its telemetry', async () => {
    await s.set('devices/bin-9', { name: 'old', fillPercent: 77, lastSeen: NOW, weightEventId: 4 });
    await adminUpsertDevice(deps(s), ADMIN, { id: 'bin-9', name: 'Yeni ad', location: 'Nizami', lat: 40.4, lng: 49.8 });
    expect(await s.get('devices/bin-9')).toMatchObject({
      name: 'Yeni ad',
      location: 'Nizami',
      lat: 40.4,
      fillPercent: 77,
      weightEventId: 4,
    });
    await expectReason(adminUpsertDevice(deps(s), ADMIN, { id: 'b', lat: 99, lng: 0 }), 'invalid-input');
  });

  it('lists only pending BakıKart requests, oldest first', async () => {
    await s.push('transportRequests', { status: 'pending', uid: ALICE, card: '1111222233334444', ep: 200, netEp: 196, fee: 4, ts: NOW + 5 });
    await s.push('transportRequests', { status: 'pending', uid: BOB, card: '5555666677778888', ep: 100, netEp: 98, fee: 2, ts: NOW });
    await s.push('transportRequests', { status: 'completed', uid: BOB, card: 'x', ep: 1, ts: NOW });
    const r = (await adminListTransport(deps(s))).requests as any[];
    expect(r.map((x) => x.uid)).toEqual([BOB, ALICE]);
  });

  it('coupon redemption is single-use and updates the owner’s copy', async () => {
    await credit(s, ALICE, 5000, { type: 'other', desc: 't' }, NOW);
    const c = await createCoupon(deps(s), ALICE, { partnerId: 'bravo', ep: 1000, requestId: 'req-cpn-0001' });
    const info = await adminLookupCoupon(deps(s), c.code.toLowerCase());
    expect(info).toMatchObject({ code: c.code, status: 'issued', owner: 'Alice' });
    expect(await adminRedeemCoupon(deps(s), ADMIN, c.code)).toMatchObject({ status: 'used' });
    await expectReason(adminRedeemCoupon(deps(s), ADMIN, c.code), 'duplicate');
    const mine = Object.values((await s.get<Record<string, any>>(`users/${ALICE}/coupons`))!);
    expect(mine[0].status).toBe('used');
    await expectReason(adminLookupCoupon(deps(s), 'not a code'), 'invalid-input');
    await expectReason(adminLookupCoupon(deps(s), 'BRA-ZZZZZZZZ'), 'not-found');
  });
});

describe('error reports', () => {
  it('stores a trimmed report, rate-limits floods, and the admin can list newest first', async () => {
    const s = new MemoryStore();
    await reportError(deps(s), ALICE, { message: 'Null check failed', stack: 'a\nb', app: '1.0.0', platform: 'android' });
    await expectReason(reportError(deps(s, NOW + 500), ALICE, { message: 'again' }), 'rate-limited');
    await reportError(deps(s, NOW + 5_000), ALICE, { message: 'second' });
    await expectReason(reportError(deps(s), ALICE, { message: '   ' }), 'invalid-input');
    const list = (await adminErrorLogs(deps(s))).errors as any[];
    expect(list.map((e) => e.message)).toEqual(['second', 'Null check failed']);
  });
});

describe('weekly leaderboard', () => {
  it('weekKey is the Monday of the Baku week', () => {
    expect(weekKey(Date.parse('2026-03-15T08:00:00Z'))).toBe('2026-03-09'); // Sunday
    expect(weekKey(Date.parse('2026-03-16T01:00:00Z'))).toBe('2026-03-16'); // Monday 05:00 Baku
    expect(weekKey(Date.parse('2026-03-15T21:00:00Z'))).toBe('2026-03-16'); // Mon 01:00 Baku
  });

  it('only EARNED EP counts (not transfers/adjustments) and is per week', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE, { name: 'Alice' });
    await claimDailyCheckIn(deps(s), ALICE, undefined);
    for (let d = 1; d <= 7; d++) {
      await claimDailyCheckIn(deps(s, NOW + d * 86_400_000), ALICE, undefined).catch(() => {});
    }
    await credit(s, ALICE, 40, { type: 'earn', desc: 'scan' }, NOW, { earned: true });
    await credit(s, ALICE, 999, { type: 'other', desc: 'admin' }, NOW);
    const wk = weekKey(NOW);
    expect(await s.get(`weeklyBoard/${wk}/${ALICE}/ep`)).toBe(40);
    expect(await s.get(`weeklyBoard/${wk}/${ALICE}/name`)).toBe('Alice');
  });
});

describe('maintenance', () => {
  it('prunes error logs older than 14 days and boards older than 4 weeks', async () => {
    const s = new MemoryStore();
    await s.push('errorLogs', { ts: NOW - 20 * 86_400_000, message: 'old' });
    await s.push('errorLogs', { ts: NOW - 1000, message: 'new' });
    await s.set(`weeklyBoard/${weekKey(NOW - 60 * 86_400_000)}/${ALICE}`, { ep: 1 });
    await s.set(`weeklyBoard/${weekKey(NOW)}/${ALICE}`, { ep: 1 });
    const r = await runMaintenance({ store: s, push: new MemoryPusher(), now: NOW });
    expect(r.sent).toBe(2);
    const left = Object.values((await s.get<Record<string, any>>('errorLogs'))!);
    expect(left.map((e) => e.message)).toEqual(['new']);
    expect(Object.keys((await s.get<Record<string, any>>('weeklyBoard'))!)).toEqual([weekKey(NOW)]);
  });

  it('runs at 03:00–06:00 Baku through the scheduler', async () => {
    const s = new MemoryStore();
    await s.push('errorLogs', { ts: NOW - 20 * 86_400_000, message: 'old' });
    const at = Date.parse('2026-03-15T00:30:00Z') /* 04:30 Baku */;
    const r = await tick({ store: s, push: new MemoryPusher() }, at);
    expect(r.maintenance?.sent).toBe(1);
  });
});
