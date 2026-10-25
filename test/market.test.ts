import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { createCoupon, purchaseReward, requestTransportTopUp } from '../src/services/market';
import { adminResolveTransport } from '../src/services/admin';
import { ALICE, BOB, NOW, balanceOf, deps, expectReason, seedUser } from './helpers';

const rid = (n: number) => `req-${String(n).padStart(8, '0')}`;
const setup = async (bal = 2000) => {
  const s = new MemoryStore();
  await seedUser(s, ALICE, { balance: bal });
  return s;
};

describe('purchaseReward', () => {
  it('charges the server price (built-in catalog) and records the purchase', async () => {
    const s = await setup();
    const r = await purchaseReward(deps(s), ALICE, { rewardId: 'p1', requestId: rid(1) });
    expect(r.balance).toBe(1850);
    expect(await s.get(`users/${ALICE}/stats/spent`)).toBe(150);
    const p = Object.values((await s.get<any>(`users/${ALICE}/purchases`))!) as any[];
    expect(p[0]).toMatchObject({ price: 150, rewardId: 'p1' });
  });

  it('is idempotent', async () => {
    const s = await setup();
    await purchaseReward(deps(s), ALICE, { rewardId: 'p1', requestId: rid(2) });
    await purchaseReward(deps(s), ALICE, { rewardId: 'p1', requestId: rid(2) });
    expect(await balanceOf(s, ALICE)).toBe(1850);
  });

  it('rejects unaffordable, unknown, and non-item rewards', async () => {
    const s = await setup(100);
    await expectReason(purchaseReward(deps(s), ALICE, { rewardId: 'p7', requestId: rid(3) }), 'insufficient-balance');
    await expectReason(purchaseReward(deps(s), ALICE, { rewardId: 'nope', requestId: rid(4) }), 'not-found');
    await expectReason(purchaseReward(deps(s), ALICE, { rewardId: 'c1', requestId: rid(5) }), 'invalid-input');
    expect(await balanceOf(s, ALICE)).toBe(100);
  });

  it('DB catalog overrides the built-in one and tracks stock', async () => {
    const s = await setup();
    await s.set('rewards/x1', { name: { az: 'X', en: 'X', ru: 'X', tr: 'X' }, ep: 10, cat: 'eco', icon: 'bag', stock: 1 });
    await purchaseReward(deps(s), ALICE, { rewardId: 'x1', requestId: rid(6) });
    expect(await s.get('rewards/x1/stock')).toBe(0);
    await expectReason(purchaseReward(deps(s), ALICE, { rewardId: 'x1', requestId: rid(7) }), 'out-of-stock');
    // old built-in ids are no longer purchasable once the DB catalog exists
    await expectReason(purchaseReward(deps(s), ALICE, { rewardId: 'p1', requestId: rid(8) }), 'not-found');
  });

  it('restores stock when the debit fails', async () => {
    const s = await setup(5);
    await s.set('rewards/x1', { name: { az: 'X', en: 'X', ru: 'X', tr: 'X' }, ep: 10, stock: 3 });
    await expectReason(purchaseReward(deps(s), ALICE, { rewardId: 'x1', requestId: rid(9) }), 'insufficient-balance');
    expect(await s.get('rewards/x1/stock')).toBe(3);
  });

  it('inactive rewards cannot be bought', async () => {
    const s = await setup();
    await s.set('rewards/x1', { name: { az: 'X' }, ep: 10, active: false });
    await expectReason(purchaseReward(deps(s), ALICE, { rewardId: 'x1', requestId: rid(10) }), 'not-found');
  });
});

describe('createCoupon', () => {
  it('debits EP, applies 5% commission, returns a code', async () => {
    const s = await setup(5000);
    const r = await createCoupon(deps(s), ALICE, { partnerId: 'bravo', ep: 1000, requestId: rid(20) });
    expect(r.balance).toBe(4000);
    expect(r.azn).toBeCloseTo(1.9, 5);
    expect(r.code).toMatch(/^BRA-[A-Z2-9]{8}$/);
    const reg = await s.get<any>(`coupons/${r.code}`);
    expect(reg).toMatchObject({ uid: ALICE, partnerId: 'bravo', status: 'issued' });
  });

  it('enforces partner minimums and known partners', async () => {
    const s = await setup(5000);
    await expectReason(createCoupon(deps(s), ALICE, { partnerId: 'bravo', ep: 499, requestId: rid(21) }), 'invalid-input');
    await createCoupon(deps(s), ALICE, { partnerId: 'bolmart', ep: 300, requestId: rid(22) });
    await expectReason(createCoupon(deps(s), ALICE, { partnerId: 'evil', ep: 1000, requestId: rid(23) }), 'invalid-input');
    await expectReason(createCoupon(deps(s), ALICE, { partnerId: 'bravo', ep: 1000.5, requestId: rid(24) }), 'invalid-input');
  });

  it('idempotent replay returns the same code, charges once', async () => {
    const s = await setup(5000);
    const a = await createCoupon(deps(s), ALICE, { partnerId: 'bravo', ep: 600, requestId: rid(25) });
    const b = await createCoupon(deps(s), ALICE, { partnerId: 'bravo', ep: 600, requestId: rid(25) });
    expect(b.code).toBe(a.code);
    expect(await balanceOf(s, ALICE)).toBe(4400);
  });
});

describe('transport top-up', () => {
  it('debits, queues a pending request, and can be refunded by an admin', async () => {
    const s = await setup(1000);
    const r = await requestTransportTopUp(deps(s), ALICE, {
      cardNumber: '1234 5678 9012 3456', ep: 400, requestId: rid(30),
    });
    expect(r.balance).toBe(600);
    const [reqId, req] = Object.entries((await s.get<any>('transportRequests'))!)[0] as [string, any];
    expect(req).toMatchObject({ uid: ALICE, ep: 400, fee: 8, status: 'pending' });
    const purchase = await s.get<any>(`users/${ALICE}/purchases/${req.purchaseId}`);
    expect(purchase.status).toBe('pending');
    expect(purchase.name).toContain('3456');
    expect(JSON.stringify(purchase)).not.toContain('1234567890123456');

    const out = await adminResolveTransport(deps(s, NOW + 1), 'admin', { requestId: reqId, approve: false });
    expect(out.status).toBe('rejected');
    expect(await balanceOf(s, ALICE)).toBe(1000);
    await expectReason(adminResolveTransport(deps(s), 'admin', { requestId: reqId, approve: false }), 'duplicate');
    expect(await balanceOf(s, ALICE)).toBe(1000);
  });

  it('validates the card and minimum', async () => {
    const s = await setup(1000);
    await expectReason(requestTransportTopUp(deps(s), ALICE, { cardNumber: '123', ep: 400, requestId: rid(31) }), 'invalid-input');
    await expectReason(requestTransportTopUp(deps(s), ALICE, { cardNumber: '1234567890123456', ep: 99, requestId: rid(32) }), 'invalid-input');
    expect(await balanceOf(s, ALICE)).toBe(1000);
  });

  it('approval keeps the debit and completes the purchase', async () => {
    const s = await setup(1000);
    await requestTransportTopUp(deps(s), ALICE, { cardNumber: '1234567890123456', ep: 200, requestId: rid(33) });
    const reqId = Object.keys((await s.get<any>('transportRequests'))!)[0];
    await adminResolveTransport(deps(s), 'admin', { requestId: reqId, approve: true });
    expect(await balanceOf(s, ALICE)).toBe(800);
  });
});

describe('BOB is unaffected', () => {
  it('other users are untouched by purchases', async () => {
    const s = await setup();
    await seedUser(s, BOB, { balance: 77 });
    await purchaseReward(deps(s), ALICE, { rewardId: 'p3', requestId: rid(40) });
    expect(await balanceOf(s, BOB)).toBe(77);
  });
});
