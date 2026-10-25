import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { deleteAccountData, ensureProfile, updateProfile } from '../src/services/profile';
import { redeemDeviceWeight } from '../src/services/devices';
import { adminAdjustBalance, issueBinCode } from '../src/services/admin';
import { parseCode, verifySignature } from '../src/lib/qr';
import { ALICE, BOB, NOW, SECRET, balanceOf, deps, expectReason, seedBin, seedUser } from './helpers';

describe('ensureProfile', () => {
  it('creates profile, referral code index and leaderboard entry without touching a balance', async () => {
    const s = new MemoryStore();
    await s.set(`users/${ALICE}/balance`, 420);
    const r = await ensureProfile(deps(s), ALICE, { name: 'Ana Li', email: 'ana@example.com' });
    expect(r.referralCode).toMatch(/^[A-Z2-9]{7}$/);
    expect(await s.get(`referralCodes/${r.referralCode}`)).toBe(ALICE);
    expect(await balanceOf(s, ALICE)).toBe(420);
    expect(await s.get(`leaderboard/${ALICE}`)).toMatchObject({ name: 'Ana Li', nameLower: 'ana li', ep: 420 });
    // idempotent
    expect((await ensureProfile(deps(s), ALICE, { name: 'Other' })).referralCode).toBe(r.referralCode);
    expect(await s.get(`users/${ALICE}/name`)).toBe('Ana Li');
  });

  it('keeps a legacy referral code when free, replaces it when taken by someone else', async () => {
    const s = new MemoryStore();
    await s.set(`users/${ALICE}/referralCode`, 'LEGACY1');
    expect((await ensureProfile(deps(s), ALICE, { email: 'a@b.co' })).referralCode).toBe('LEGACY1');
    await s.set(`users/${BOB}/referralCode`, 'LEGACY1');
    const r = await ensureProfile(deps(s), BOB, { email: 'b@b.co' });
    expect(r.referralCode).not.toBe('LEGACY1');
    expect(await s.get('referralCodes/LEGACY1')).toBe(ALICE);
  });

  it('falls back to the e-mail prefix for the name', async () => {
    const s = new MemoryStore();
    await ensureProfile(deps(s), ALICE, { email: 'rufat@example.com' });
    expect(await s.get(`users/${ALICE}/name`)).toBe('rufat');
  });
});

describe('updateProfile', () => {
  it('sanitises and syncs the public leaderboard entry', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE, { balance: 10 });
    await updateProfile(deps(s), ALICE, { name: '  Ana​   Li ', bio: 'Hi\u0000!', avatar: 'leaf' });
    expect(await s.get(`users/${ALICE}/name`)).toBe('Ana Li');
    expect(await s.get(`users/${ALICE}/bio`)).toBe('Hi!');
    expect(await s.get(`leaderboard/${ALICE}`)).toMatchObject({ name: 'Ana Li', nameLower: 'ana li', avatar: 'leaf', ep: 10 });
  });
  it('rejects short names and bad avatars', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await expectReason(updateProfile(deps(s), ALICE, { name: 'A', bio: '', avatar: '' }), 'invalid-input');
    await expectReason(updateProfile(deps(s), ALICE, { name: 'Ana', bio: '', avatar: '../x' }), 'invalid-input');
  });
});

describe('deleteAccountData', () => {
  it('removes private data, leaderboard entry and the referral code', async () => {
    const s = new MemoryStore();
    const { referralCode } = await ensureProfile(deps(s), ALICE, { name: 'Ana Li' });
    await seedUser(s, BOB);
    await deleteAccountData(deps(s), ALICE);
    expect(await s.get(`users/${ALICE}`)).toBeNull();
    expect(await s.get(`leaderboard/${ALICE}`)).toBeNull();
    expect(await s.get(`referralCodes/${referralCode}`)).toBeNull();
    expect(await s.get(`users/${BOB}`)).not.toBeNull();
  });
});

describe('redeemDeviceWeight', () => {
  async function setup(extra: Record<string, unknown> = {}) {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await seedUser(s, BOB);
    await seedBin(s, 'dev1', { weight: 250, weightEventId: 7, ...extra });
    return s;
  }

  it('pays 10 EP per full 100 g and the reading is single-use', async () => {
    const s = await setup();
    const r = await redeemDeviceWeight(deps(s), ALICE, { deviceId: 'dev1' });
    expect(r).toMatchObject({ ep: 20, grams: 250, balance: 20 });
    await expectReason(redeemDeviceWeight(deps(s, NOW + 60_000), BOB, { deviceId: 'dev1' }), 'duplicate');
    expect(await balanceOf(s, BOB)).toBe(0);
    // a new deposit gets a new event id
    await s.update('devices/dev1', { weightEventId: 8, lastSeen: NOW + 60_000 });
    expect((await redeemDeviceWeight(deps(s, NOW + 61_000), BOB, { deviceId: 'dev1' })).ep).toBe(20);
  });

  it('rejects bins without weightEventId, offline bins, tiny and absurd readings', async () => {
    const s = await setup({ weightEventId: null });
    await expectReason(redeemDeviceWeight(deps(s), ALICE, { deviceId: 'dev1' }), 'invalid-input');
    await expectReason(redeemDeviceWeight(deps(s), ALICE, { deviceId: 'nope' }), 'not-found');

    const off = await setup({ lastSeen: NOW - 3_600_000 });
    await expectReason(redeemDeviceWeight(deps(off), ALICE, { deviceId: 'dev1' }), 'invalid-input');
    const tiny = await setup({ weight: 60 });
    await expectReason(redeemDeviceWeight(deps(tiny), ALICE, { deviceId: 'dev1' }), 'invalid-input');
    const huge = await setup({ weight: 50_000 });
    await expectReason(redeemDeviceWeight(deps(huge), ALICE, { deviceId: 'dev1' }), 'invalid-input');
    expect(await balanceOf(huge, ALICE)).toBe(0);
  });

  it('enforces the per-bin cooldown and the daily weight cap', async () => {
    const s = await setup();
    await redeemDeviceWeight(deps(s), ALICE, { deviceId: 'dev1' });
    await s.update('devices/dev1', { weightEventId: 8 });
    await expectReason(redeemDeviceWeight(deps(s, NOW + 5_000), BOB, { deviceId: 'dev1' }), 'rate-limited');

    const capped = await setup();
    await capped.set(`users/${ALICE}/daily/2026-03-15`, { ep: 0, scans: 0, grams: 4_900 });
    await expectReason(redeemDeviceWeight(deps(capped), ALICE, { deviceId: 'dev1' }), 'daily-limit');
    expect(await capped.get('weightEvents/dev1_7')).toBeNull();
  });
});

describe('admin', () => {
  it('adjusts balances both ways, never below zero, and logs', async () => {
    const s = new MemoryStore();
    await seedUser(s, ALICE, { balance: 100 });
    expect((await adminAdjustBalance(deps(s), 'admin', { uid: ALICE, delta: 50, reason: 'gift' })).balance).toBe(150);
    expect((await adminAdjustBalance(deps(s), 'admin', { uid: ALICE, delta: -150, reason: 'fix' })).balance).toBe(0);
    await expectReason(adminAdjustBalance(deps(s), 'admin', { uid: ALICE, delta: -1, reason: '' }), 'insufficient-balance');
    await expectReason(adminAdjustBalance(deps(s), 'admin', { uid: ALICE, delta: 0, reason: '' }), 'invalid-input');
    expect(Object.keys((await s.get<any>('adminLog'))!)).toHaveLength(2);
  });

  it('issues verifiable bin codes with bounded TTL', () => {
    const { code, expiresAt } = issueBinCode(SECRET, 'bin-01', 99_999_999, NOW);
    expect(expiresAt).toBe(Math.floor(NOW / 1000) + 300); // out-of-range ttl falls back to default
    const parsed = parseCode(code)!;
    expect(verifySignature(SECRET, parsed)).toBe(true);
    expect(() => issueBinCode(SECRET, '../x', 60, NOW)).toThrow();
  });
});
