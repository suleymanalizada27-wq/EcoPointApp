import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { lookupUsers, transferEp } from '../src/services/transfer';
import { ALICE, BOB, NOW, balanceOf, deps, expectReason, seedUser } from './helpers';

const rid = (n: number) => `req-${String(n).padStart(8, '0')}`;

async function setup(aliceBal = 1000, bobBal = 0) {
  const s = new MemoryStore();
  await seedUser(s, ALICE, { balance: aliceBal, name: 'Alice Ahmadova' });
  await seedUser(s, BOB, { balance: bobBal, name: 'Bob Bayramov' });
  return s;
}

describe('transferEp', () => {
  it('moves EP, writes both histories, stats and leaderboard', async () => {
    const s = await setup();
    const r = await transferEp(deps(s), ALICE, { recipientUid: BOB, amount: 300, requestId: rid(1) });
    expect(r).toMatchObject({ balance: 700, recipientName: 'Bob Bayramov' });
    expect(await balanceOf(s, ALICE)).toBe(700);
    expect(await balanceOf(s, BOB)).toBe(300);
    expect(await s.get(`users/${ALICE}/stats/sent`)).toBe(300);
    expect(await s.get(`leaderboard/${BOB}/ep`)).toBe(300);
    const a = Object.values((await s.get<any>(`users/${ALICE}/transactions`))!) as any[];
    const b = Object.values((await s.get<any>(`users/${BOB}/transactions`))!) as any[];
    expect(a[0]).toMatchObject({ type: 'sent', amount: '-300' });
    expect(b[0]).toMatchObject({ type: 'received', amount: '+300' });
  });

  it('never lets a balance go negative', async () => {
    const s = await setup(100);
    await expectReason(
      transferEp(deps(s), ALICE, { recipientUid: BOB, amount: 101, requestId: rid(2) }),
      'insufficient-balance',
    );
    expect(await balanceOf(s, ALICE)).toBe(100);
    expect(await balanceOf(s, BOB)).toBe(0);
  });

  it('a user with no balance record cannot spend', async () => {
    const s = await setup();
    await s.remove(`users/${ALICE}/balance`);
    await expectReason(
      transferEp(deps(s), ALICE, { recipientUid: BOB, amount: 5, requestId: rid(3) }),
      'insufficient-balance',
    );
  });

  it('concurrent transfers cannot double-spend', async () => {
    const s = await setup(100);
    const res = await Promise.allSettled([
      transferEp(deps(s), ALICE, { recipientUid: BOB, amount: 80, requestId: rid(4) }),
      transferEp(deps(s), ALICE, { recipientUid: BOB, amount: 80, requestId: rid(5) }),
    ]);
    expect(res.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(await balanceOf(s, ALICE)).toBe(20);
    expect(await balanceOf(s, BOB)).toBe(80);
  });

  it('is idempotent: a retried request does not pay twice', async () => {
    const s = await setup();
    const input = { recipientUid: BOB, amount: 100, requestId: rid(6) };
    const first = await transferEp(deps(s), ALICE, input);
    const again = await transferEp(deps(s, NOW + 1000), ALICE, input);
    expect(again).toEqual(first);
    expect(await balanceOf(s, ALICE)).toBe(900);
    expect(await balanceOf(s, BOB)).toBe(100);
  });

  it('validates input', async () => {
    const s = await setup();
    const bad = (o: Partial<{ recipientUid: unknown; amount: unknown; requestId: unknown }>) =>
      transferEp(deps(s), ALICE, { recipientUid: BOB, amount: 10, requestId: rid(7), ...o });
    await expectReason(bad({ recipientUid: ALICE }), 'self-transfer');
    await expectReason(bad({ recipientUid: 'x' }), 'invalid-input');
    await expectReason(bad({ amount: 0 }), 'invalid-input');
    await expectReason(bad({ amount: -5 }), 'invalid-input');
    await expectReason(bad({ amount: 1.5 }), 'invalid-input');
    await expectReason(bad({ amount: '10' }), 'invalid-input');
    await expectReason(bad({ amount: 10_001 }), 'invalid-input');
    await expectReason(bad({ requestId: undefined }), 'invalid-input');
    await expectReason(bad({ recipientUid: 'ghostGhostGhostGhost99' }), 'not-found');
    expect(await balanceOf(s, ALICE)).toBe(1000);
  });

  it('limits transfers per hour', async () => {
    const s = await setup(100_000);
    for (let i = 0; i < 20; i++) {
      await transferEp(deps(s, NOW + i), ALICE, { recipientUid: BOB, amount: 1, requestId: rid(100 + i) });
    }
    await expectReason(
      transferEp(deps(s, NOW + 50), ALICE, { recipientUid: BOB, amount: 1, requestId: rid(999) }),
      'rate-limited',
    );
  });

  it('refunds the sender if crediting the recipient fails', async () => {
    const s = await setup();
    const real = s.transaction.bind(s);
    s.transaction = async (path, fn) => {
      if (path === `users/${BOB}/balance`) throw new Error('db down');
      return real(path, fn);
    };
    await expect(
      transferEp(deps(s), ALICE, { recipientUid: BOB, amount: 250, requestId: rid(8) }),
    ).rejects.toThrow('db down');
    expect(await balanceOf(s, ALICE)).toBe(1000);
    expect(await s.get(`users/${ALICE}/stats/sent`)).toBe(0);
  });
});

describe('lookupUsers', () => {
  it('finds by case-insensitive name prefix, excludes self, never exposes balances', async () => {
    const s = await setup(5000, 7);
    await seedUser(s, 'carolCarolCarolCarol03', { name: 'Bobby Tables' });
    const r = await lookupUsers(deps(s), ALICE, 'bob');
    expect(r.users.map((u) => u.name).sort()).toEqual(['Bob Bayramov', 'Bobby Tables'].sort());
    for (const u of r.users) expect(Object.keys(u).sort()).toEqual(['avatar', 'name', 'photoURL', 'uid']);
    expect((await lookupUsers(deps(s), ALICE, 'alice')).users).toHaveLength(0);
  });

  it('finds by exact uid and ignores too-short queries', async () => {
    const s = await setup();
    expect((await lookupUsers(deps(s), ALICE, BOB)).users[0].uid).toBe(BOB);
    expect((await lookupUsers(deps(s), ALICE, 'b')).users).toEqual([]);
  });
});
