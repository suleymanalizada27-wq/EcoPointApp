import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { deleteAccountData, ensureProfile, updateProfile } from '../src/services/profile';
import { adminAdjustBalance, binQr } from '../src/services/admin';
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

  it('issues the static bin QR and rejects bad ids', () => {
    const { code } = binQr(SECRET, 'bin-01');
    expect(code).toMatch(/^EP2:bin-01:/);
    expect(verifySignature(SECRET, parseCode(code)!)).toBe(true);
    expect(() => binQr(SECRET, '../x')).toThrow();
  });
});
