import { describe, expect, it } from 'vitest';
import { buildCode, depositMac, deviceKey, parseCode, sign, verifyDepositMac, verifySignature } from '../src/lib/qr';
import { MemoryStore } from '../src/store';
import {
  cancelSession,
  deviceDeposit,
  openSession,
  sessionStatus,
  simulateDeposit,
  SESSION_TTL_MS,
} from '../src/services/sessions';
import { ALICE, BOB, NOW, SECRET, balanceOf, deps, expectReason, seedBin, seedUser } from './helpers';

const code = (binId = 'bin-01') => buildCode(SECRET, binId);

/** What a real bin firmware sends. */
function deposit(binId: string, eventId: string, grams: number, ts: number, secret = SECRET) {
  const m = { binId, eventId, grams, ts };
  return { ...m, mac: depositMac(deviceKey(secret, binId), m) };
}

describe('static QR format (EP2)', () => {
  it('round-trips, never expires, carries no reward', () => {
    expect(code()).toMatch(/^EP2:bin-01:[0-9a-f]{32}$/);
    const c = parseCode(code())!;
    expect(c.binId).toBe('bin-01');
    expect(verifySignature(SECRET, c)).toBe(true);
    expect(code()).toBe(code()); // static: the same every time
  });
  it('rejects a different secret, tampered ids and junk (incl. old EP1 codes)', () => {
    const c = parseCode(code())!;
    expect(verifySignature('other', c)).toBe(false);
    expect(verifySignature(SECRET, { ...c, binId: 'bin-02' })).toBe(false);
    expect(parseCode('hello')).toBeNull();
    expect(parseCode(42)).toBeNull();
    expect(parseCode(`EP1:bin:n:100:${sign(SECRET, 'bin')}`)).toBeNull();
    expect(parseCode('EP2:bin-01:short')).toBeNull();
    expect(parseCode('EP2:bi n:' + '0'.repeat(32))).toBeNull();
  });
  it('deposit MAC binds every field and the bin key', () => {
    const m = { binId: 'bin-01', eventId: 'e1', grams: 250, ts: NOW };
    const mac = depositMac(deviceKey(SECRET, 'bin-01'), m);
    expect(verifyDepositMac(deviceKey(SECRET, 'bin-01'), m, mac)).toBe(true);
    expect(verifyDepositMac(deviceKey(SECRET, 'bin-01'), { ...m, grams: 251 }, mac)).toBe(false);
    expect(verifyDepositMac(deviceKey(SECRET, 'bin-02'), m, mac)).toBe(false);
    expect(verifyDepositMac(deviceKey(SECRET, 'bin-01'), m, 'nope')).toBe(false);
    expect(verifyDepositMac(deviceKey(SECRET, 'bin-01'), m, undefined)).toBe(false);
  });
});

describe('scan → session → bin confirms → scanner is paid', () => {
  async function setup() {
    const s = new MemoryStore();
    await seedUser(s, ALICE);
    await seedUser(s, BOB);
    await seedBin(s);
    return s;
  }

  it('the person who scanned gets the EP, stats, transaction and leaderboard', async () => {
    const s = await setup();
    const sess = await openSession(deps(s), SECRET, ALICE, code());
    expect(sess).toMatchObject({ binId: 'bin-01', expiresAt: NOW + SESSION_TTL_MS });
    expect((await sessionStatus(deps(s), ALICE, { sessionId: sess.sessionId })).status).toBe('open');

    const r = await deviceDeposit(deps(s, NOW + 20_000), SECRET, deposit('bin-01', 'ev1', 250, NOW + 20_000));
    expect(r).toMatchObject({ ep: 20, grams: 250, balance: 20, multiplier: 1 });
    expect(await balanceOf(s, ALICE)).toBe(20);
    expect(await balanceOf(s, BOB)).toBe(0);
    expect(await s.get(`users/${ALICE}/stats/scans`)).toBe(1);
    expect(await s.get(`leaderboard/${ALICE}/ep`)).toBe(20);
    expect(await s.get(`users/${ALICE}/monthly/2026-03/scans`)).toBe(1);

    const st = await sessionStatus(deps(s, NOW + 21_000), ALICE, { sessionId: sess.sessionId });
    expect(st.status).toBe('done');
    expect(st.result).toMatchObject({ ep: 20, balance: 20 });
    // another person cannot read this session
    await expectReason(sessionStatus(deps(s), BOB, { sessionId: sess.sessionId }), 'not-found');
  });

  it('a bin without a scale pays the flat scan reward; Pro doubles', async () => {
    const s = await setup();
    await s.update(`users/${ALICE}`, { isPro: true });
    await openSession(deps(s), SECRET, ALICE, code());
    const r = await deviceDeposit(deps(s, NOW + 1000), SECRET, deposit('bin-01', 'ev2', 0, NOW + 1000));
    expect(r).toMatchObject({ ep: 100, baseEp: 50, multiplier: 2 });
  });

  it('forged or unsigned QR codes cannot open a session', async () => {
    const s = await setup();
    await expectReason(openSession(deps(s), SECRET, ALICE, 'EP2:bin-01:' + '0'.repeat(32)), 'invalid-qr');
    await expectReason(openSession(deps(s), SECRET, ALICE, buildCode('attacker', 'bin-01')), 'invalid-qr');
    await expectReason(openSession(deps(s), SECRET, ALICE, 'whatever'), 'invalid-qr');
    await expectReason(openSession(deps(s), SECRET, ALICE, code('ghost-bin')), 'invalid-qr');
    await s.update('devices/bin-01', { disabled: true });
    await expectReason(openSession(deps(s), SECRET, ALICE, code()), 'bin-disabled');
  });

  it('a deposit with no open session pays nothing and burns nothing', async () => {
    const s = await setup();
    await expectReason(deviceDeposit(deps(s), SECRET, deposit('bin-01', 'ev3', 300, NOW)), 'no-session');
    expect(await s.get('weightEvents/bin-01_ev3')).toBeNull();
    // person scans afterwards; the same event id (bin retry) now works
    await openSession(deps(s, NOW + 5000), SECRET, ALICE, code());
    expect((await deviceDeposit(deps(s, NOW + 6000), SECRET, deposit('bin-01', 'ev3', 300, NOW + 6000))).ep).toBe(30);
  });

  it('forged, stale and tampered deposit messages are rejected', async () => {
    const s = await setup();
    await openSession(deps(s), SECRET, ALICE, code());
    await expectReason(deviceDeposit(deps(s), SECRET, deposit('bin-01', 'e', 500, NOW, 'attacker')), 'forbidden');
    const d = deposit('bin-01', 'e', 500, NOW);
    await expectReason(deviceDeposit(deps(s), SECRET, { ...d, grams: 5000 }), 'forbidden');
    await expectReason(deviceDeposit(deps(s), SECRET, { ...d, mac: undefined }), 'forbidden');
    await expectReason(deviceDeposit(deps(s, NOW + 10 * 60_000), SECRET, d), 'invalid-input');
    await expectReason(deviceDeposit(deps(s), SECRET, { ...d, grams: -5 }), 'invalid-input');
    expect(await balanceOf(s, ALICE)).toBe(0);
  });

  it('the same event is paid once; a re-send returns the first result', async () => {
    const s = await setup();
    await openSession(deps(s), SECRET, ALICE, code());
    const msg = deposit('bin-01', 'once', 200, NOW + 1000);
    const a = await deviceDeposit(deps(s, NOW + 1000), SECRET, msg);
    const b = await deviceDeposit(deps(s, NOW + 2000), SECRET, { ...msg });
    expect(b).toMatchObject({ ep: a.ep, duplicate: true });
    expect(await balanceOf(s, ALICE)).toBe(20);
    // …and it cannot be replayed onto someone else's later session
    await openSession(deps(s, NOW + 9000), SECRET, BOB, code());
    const c = await deviceDeposit(deps(s, NOW + 9500), SECRET, msg);
    expect(c.duplicate).toBe(true);
    expect(await balanceOf(s, BOB)).toBe(0);
  });

  it('two simultaneous deposits for one session pay exactly once', async () => {
    const s = await setup();
    await openSession(deps(s), SECRET, ALICE, code());
    const res = await Promise.allSettled([
      deviceDeposit(deps(s, NOW + 1000), SECRET, deposit('bin-01', 'r1', 200, NOW + 1000)),
      deviceDeposit(deps(s, NOW + 1000), SECRET, deposit('bin-01', 'r2', 200, NOW + 1000)),
    ]);
    expect(res.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(await balanceOf(s, ALICE)).toBe(20);
  });

  it('one person at a time per bin; the same person gets the same session back; it expires', async () => {
    const s = await setup();
    const a = await openSession(deps(s), SECRET, ALICE, code());
    await expectReason(openSession(deps(s, NOW + 4000), SECRET, BOB, code()), 'bin-busy');
    const again = await openSession(deps(s, NOW + 5000), SECRET, ALICE, code());
    expect(again.sessionId).toBe(a.sessionId);
    // after the TTL the bin is free for Bob and Alice's session shows as expired
    const bob = await openSession(deps(s, NOW + SESSION_TTL_MS + 1000), SECRET, BOB, code());
    expect(bob.sessionId).not.toBe(a.sessionId);
    expect((await sessionStatus(deps(s, NOW + SESSION_TTL_MS + 1000), ALICE, { sessionId: a.sessionId })).status).toBe('expired');
  });

  it('a deposit after the session expired pays nothing', async () => {
    const s = await setup();
    await openSession(deps(s), SECRET, ALICE, code());
    const late = NOW + SESSION_TTL_MS + 1;
    await expectReason(deviceDeposit(deps(s, late), SECRET, deposit('bin-01', 'late', 300, late)), 'no-session');
    expect(await balanceOf(s, ALICE)).toBe(0);
  });

  it('cancel frees the bin immediately', async () => {
    const s = await setup();
    const a = await openSession(deps(s), SECRET, ALICE, code());
    await cancelSession(deps(s), ALICE, { sessionId: a.sessionId });
    await openSession(deps(s, NOW + 4000), SECRET, BOB, code());
    expect((await deviceDeposit(deps(s, NOW + 5000), SECRET, deposit('bin-01', 'c', 300, NOW + 5000))).ep).toBe(30);
    expect(await balanceOf(s, BOB)).toBe(30);
    expect(await balanceOf(s, ALICE)).toBe(0);
  });

  it('daily cap fails the deposit, frees the bin and the event id', async () => {
    const s = await setup();
    await s.set(`users/${ALICE}/daily/2026-03-15`, { ep: 0, scans: 0, grams: 4_900 });
    const sess = await openSession(deps(s), SECRET, ALICE, code());
    await expectReason(deviceDeposit(deps(s, NOW + 1000), SECRET, deposit('bin-01', 'cap', 300, NOW + 1000)), 'daily-limit');
    expect(await balanceOf(s, ALICE)).toBe(0);
    expect(await s.get('weightEvents/bin-01_cap')).toBeNull();
    expect((await sessionStatus(deps(s, NOW + 2000), ALICE, { sessionId: sess.sessionId })).status).toBe('failed');
    await openSession(deps(s, NOW + 5000), SECRET, BOB, code()); // bin is free again
  });

  it('banned users cannot open sessions; scans are rate limited', async () => {
    const s = await setup();
    await s.set(`security/banned/${ALICE}`, true);
    await expectReason(openSession(deps(s), SECRET, ALICE, code()), 'banned');
    await openSession(deps(s), SECRET, BOB, code());
    await cancelSession(deps(s), BOB, { sessionId: (await s.get<any>('binActive/bin-01')).sid }).catch(() => undefined);
    await expectReason(openSession(deps(s, NOW + 500), SECRET, BOB, code()), 'rate-limited');
  });

  it('the virtual-bin simulator uses the real path and only when enabled', async () => {
    const s = await setup();
    await openSession(deps(s), SECRET, ALICE, code());
    await expectReason(simulateDeposit(deps(s, NOW + 1000), SECRET, { binId: 'bin-01', grams: 400 }), 'forbidden');
    const r = await simulateDeposit({ ...deps(s, NOW + 1000), sim: true }, SECRET, { binId: 'bin-01', grams: 400 });
    expect(r.ep).toBe(40);
    expect(await balanceOf(s, ALICE)).toBe(40);
    await expectReason(simulateDeposit({ ...deps(s, NOW + 2000), sim: true }, SECRET, { binId: 'bin-01', grams: 400 }), 'no-session');
  });
});
