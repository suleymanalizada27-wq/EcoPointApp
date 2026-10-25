import { describe, expect, it } from 'vitest';
import { buildCode, parseCode, sign, verifySignature } from '../src/lib/qr';
import { MemoryStore } from '../src/store';
import { redeemQr } from '../src/services/qr';
import { ALICE, BOB, NOW, SECRET, balanceOf, deps, expectReason, seedBin, seedUser } from './helpers';

const exp = Math.floor(NOW / 1000) + 300;
const mint = (nonce = 'n0nce0001', binId = 'bin-01', e = exp) => buildCode(SECRET, binId, nonce, e);

describe('QR code format', () => {
  it('round-trips and verifies', () => {
    const c = parseCode(mint())!;
    expect(c.binId).toBe('bin-01');
    expect(verifySignature(SECRET, c)).toBe(true);
  });
  it('rejects a different secret, tampered fields and junk', () => {
    const c = parseCode(mint())!;
    expect(verifySignature('other', c)).toBe(false);
    expect(verifySignature(SECRET, { ...c, binId: 'bin-02' })).toBe(false);
    expect(verifySignature(SECRET, { ...c, exp: c.exp + 1 })).toBe(false);
    expect(parseCode('hello')).toBeNull();
    expect(parseCode(42)).toBeNull();
    expect(parseCode(`EP1:bin:n:abc:${sign(SECRET, 'bin', 'n', 1)}`)).toBeNull();
    expect(parseCode('EP1:bin:n:100:short')).toBeNull();
  });
});

describe('redeemQr', () => {
  async function setup() {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await seedUser(s, BOB);
    await seedBin(s);
    return s;
  }

  it('pays 50 EP for a valid code and updates stats, tx, leaderboard', async () => {
    const s = await setup();
    const r = await redeemQr(deps(s), SECRET, ALICE, mint());
    expect(r).toMatchObject({ ep: 50, baseEp: 50, multiplier: 1, balance: 50, binId: 'bin-01' });
    expect(await balanceOf(s, ALICE)).toBe(50);
    expect(await s.get(`users/${ALICE}/stats/scans`)).toBe(1);
    expect(await s.get(`users/${ALICE}/stats/earned`)).toBe(50);
    expect(await s.get(`leaderboard/${ALICE}/ep`)).toBe(50);
    const txs = Object.values((await s.get<any>(`users/${ALICE}/transactions`))!) as any[];
    expect(txs).toHaveLength(1);
    expect(txs[0]).toMatchObject({ type: 'earn', amount: '+50', rawAmount: 50 });
  });

  it('doubles for active Pro, not for expired Pro', async () => {
    const s = await setup();
    await s.update(`users/${ALICE}`, { isPro: true });
    expect((await redeemQr(deps(s), SECRET, ALICE, mint('proaaaaa1'))).ep).toBe(100);
    await s.update(`users/${BOB}`, { isPro: true, proExpiry: NOW - 1 });
    expect((await redeemQr(deps(s), SECRET, BOB, mint('probbbbb2'))).ep).toBe(50);
  });

  it('rejects forged / unsigned / wrong-secret codes and pays nothing', async () => {
    const s = await setup();
    await expectReason(redeemQr(deps(s), SECRET, ALICE, 'EP1:bin-01:abc:9999999999:' + '0'.repeat(32)), 'invalid-qr');
    await expectReason(redeemQr(deps(s), SECRET, ALICE, buildCode('attacker', 'bin-01', 'n1', exp)), 'invalid-qr');
    await expectReason(redeemQr(deps(s), SECRET, ALICE, 'some-random-text'), 'invalid-qr');
    await expectReason(redeemQr(deps(s), SECRET, ALICE, undefined), 'invalid-qr');
    expect(await balanceOf(s, ALICE)).toBe(0);
  });

  it('rejects expired codes', async () => {
    const s = await setup();
    await expectReason(
      redeemQr(deps(s), SECRET, ALICE, mint('old000001', 'bin-01', Math.floor(NOW / 1000) - 1)),
      'expired-qr',
    );
  });

  it('rejects codes for unknown bins', async () => {
    const s = await setup();
    await expectReason(redeemQr(deps(s), SECRET, ALICE, mint('n1111111', 'ghost-bin')), 'invalid-qr');
  });

  it('a code can be used only once — by anyone', async () => {
    const s = await setup();
    const code = mint('single001');
    await redeemQr(deps(s), SECRET, ALICE, code);
    await expectReason(redeemQr(deps(s, NOW + 10_000), SECRET, ALICE, code), 'duplicate');
    await expectReason(redeemQr(deps(s, NOW + 10_000), SECRET, BOB, code), 'duplicate');
    expect(await balanceOf(s, ALICE)).toBe(50);
    expect(await balanceOf(s, BOB)).toBe(0);
  });

  it('concurrent redemption of the same code pays exactly once', async () => {
    const s = await setup();
    const code = mint('race00001');
    const results = await Promise.allSettled([
      redeemQr(deps(s), SECRET, ALICE, code),
      redeemQr(deps(s), SECRET, BOB, code),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect((await balanceOf(s, ALICE)) + (await balanceOf(s, BOB))).toBe(50);
  });

  it('enforces the minimum interval between scans', async () => {
    const s = await setup();
    await redeemQr(deps(s), SECRET, ALICE, mint('a0000001'));
    await expectReason(redeemQr(deps(s, NOW + 500), SECRET, ALICE, mint('a0000002')), 'rate-limited');
    await redeemQr(deps(s, NOW + 4000), SECRET, ALICE, mint('a0000003'));
    expect(await balanceOf(s, ALICE)).toBe(100);
  });

  it('allows at most 10 scans per hour', async () => {
    const s = await setup();
    for (let i = 0; i < 10; i++) {
      await redeemQr(deps(s, NOW + i * 4000), SECRET, ALICE, mint(`h${i}000000`));
    }
    await expectReason(redeemQr(deps(s, NOW + 11 * 4000), SECRET, ALICE, mint('h9999999')), 'rate-limited');
    // …and the failed attempt did not burn the code.
    expect(await s.get('qrNonces/bin-01_h9999999')).toBeNull();
  });

  it('applies the daily EP cap and releases the code when blocked', async () => {
    const s = await setup();
    await s.set(`users/${ALICE}/daily/2026-03-15`, { ep: 4980, scans: 0, grams: 0 });
    await expectReason(redeemQr(deps(s), SECRET, ALICE, mint('cap000001')), 'daily-limit');
    expect(await balanceOf(s, ALICE)).toBe(0);
    expect(await s.get('qrNonces/bin-01_cap000001')).toBeNull();
    // someone else can still use that code
    expect((await redeemQr(deps(s), SECRET, BOB, mint('cap000001'))).ep).toBe(50);
  });

  it('blocks banned users', async () => {
    const s = await setup();
    await s.set(`security/banned/${ALICE}`, true);
    await expectReason(redeemQr(deps(s), SECRET, ALICE, mint('ban000001')), 'banned');
  });
});
