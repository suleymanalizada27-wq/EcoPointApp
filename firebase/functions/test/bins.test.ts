import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { MemoryPusher } from '../src/push';
import { tick } from '../src/scheduler';
import { registerPushToken } from '../src/services/push-tokens';
import {
  adminListReports,
  adminReportPhoto,
  adminResolveReport,
  reportBin,
  runBinFullAlerts,
  toggleFavBin,
} from '../src/services/bins';
import { ALICE, BOB, NOW, deps, expectReason, seedBin, seedUser } from './helpers';

const JPEG = '/9j/4AAQSkZJRgABAQEASABIAAD';

async function setup() {
  const s = new MemoryStore();
  await seedUser(s, ALICE);
  await seedUser(s, BOB);
  await seedBin(s, 'bin-01');
  return s;
}

describe('bin problem reports', () => {
  it('stores a report with an optional photo; admin lists, views and resolves it', async () => {
    const s = await setup();
    const { id } = await reportBin(deps(s), ALICE, { binId: 'bin-01', kind: 'full', note: ' çox dolub ', photo: JPEG });
    const list = (await adminListReports(deps(s))).reports as any[];
    expect(list).toHaveLength(1);
    expect(list[0]).toMatchObject({ id, binId: 'bin-01', kind: 'full', hasPhoto: true, uid: ALICE });
    expect((await adminReportPhoto(deps(s), id)).photo).toBe(JPEG);
    await adminResolveReport(deps(s), 'admin', { id });
    expect((await adminListReports(deps(s))).reports).toHaveLength(0);
    expect((await adminReportPhoto(deps(s), id)).photo).toBeNull();
    // after resolving, the person may report again
    await reportBin(deps(s, NOW + 10_000), ALICE, { binId: 'bin-01', kind: 'dirty' });
  });

  it('validates input: kind, bin, photo type/size; one open report per person per bin', async () => {
    const s = await setup();
    await expectReason(reportBin(deps(s), ALICE, { binId: 'bin-01', kind: 'nope' }), 'invalid-input');
    await expectReason(reportBin(deps(s), ALICE, { binId: 'ghost', kind: 'full' }), 'not-found');
    await expectReason(reportBin(deps(s), ALICE, { binId: 'bin-01', kind: 'full', photo: 'not base64!' }), 'invalid-input');
    await expectReason(reportBin(deps(s), ALICE, { binId: 'bin-01', kind: 'full', photo: 'AAAA' }), 'invalid-input');
    await expectReason(reportBin(deps(s), ALICE, { binId: 'bin-01', kind: 'full', photo: '/9j/' + 'A'.repeat(400_000) }), 'invalid-input');
    await reportBin(deps(s), ALICE, { binId: 'bin-01', kind: 'full' });
    await expectReason(reportBin(deps(s, NOW + 10_000), ALICE, { binId: 'bin-01', kind: 'broken' }), 'duplicate');
  });

  it('the map flag "problem" needs two different people reporting "broken"; admin can clear it', async () => {
    const s = await setup();
    const a = await reportBin(deps(s), ALICE, { binId: 'bin-01', kind: 'broken' });
    expect((await s.get<any>('devices/bin-01')).problem).toBeUndefined();
    await reportBin(deps(s, NOW + 10_000), BOB, { binId: 'bin-01', kind: 'broken' });
    expect((await s.get<any>('devices/bin-01')).problem).toBe(true);
    await adminResolveReport(deps(s), 'admin', { id: a.id, clearProblem: true });
    expect((await s.get<any>('devices/bin-01')).problem).toBe(false);
  });

  it('rate limits reports', async () => {
    const s = await setup();
    for (let i = 0; i < 6; i++) {
      await seedBin(s, `b${i}`);
      await reportBin(deps(s, NOW + i * 6_000), ALICE, { binId: `b${i}`, kind: 'full' });
    }
    await seedBin(s, 'b9');
    await expectReason(reportBin(deps(s, NOW + 40_000), ALICE, { binId: 'b9', kind: 'full' }), 'rate-limited');
  });
});

describe('favourite bins and "almost full" alerts', () => {
  it('toggles favourites, keeps the index in sync, caps at 10', async () => {
    const s = await setup();
    expect((await toggleFavBin(deps(s), ALICE, { binId: 'bin-01', on: true })).favs).toEqual(['bin-01']);
    expect(await s.get(`favIndex/bin-01/${ALICE}`)).toBe(true);
    expect((await toggleFavBin(deps(s), ALICE, { binId: 'bin-01', on: false })).favs).toEqual([]);
    expect(await s.get(`favIndex/bin-01/${ALICE}`)).toBeNull();
    await expectReason(toggleFavBin(deps(s), ALICE, { binId: 'ghost', on: true }), 'not-found');
    for (let i = 0; i < 10; i++) {
      await seedBin(s, `f${i}`);
      await toggleFavBin(deps(s), ALICE, { binId: `f${i}`, on: true });
    }
    await expectReason(toggleFavBin(deps(s), ALICE, { binId: 'bin-01', on: true }), 'invalid-input');
  });

  it('alerts the people who starred a bin once when it fills up, re-arms after it is emptied', async () => {
    const s = await setup();
    const push = new MemoryPusher();
    await registerPushToken({ store: s, now: 1 }, ALICE, { token: 'tokenBINAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', lang: 'en' });
    await toggleFavBin(deps(s), ALICE, { binId: 'bin-01', on: true });
    await toggleFavBin(deps(s), BOB, { binId: 'bin-01', on: true }); // Bob has no device: harmless

    expect((await runBinFullAlerts({ store: s, push, now: NOW })).sent).toBe(0); // 10 % full
    await s.update('devices/bin-01', { fillPercent: 92, lastSeen: NOW });
    expect((await runBinFullAlerts({ store: s, push, now: NOW })).sent).toBe(2);
    expect(push.user.find((m) => m.uid === ALICE)).toMatchObject({ kind: 'binFull', route: '/bins' });
    expect(push.user[0].body).toContain('92%');
    // not again while it stays full
    expect((await runBinFullAlerts({ store: s, push, now: NOW + 3_600_000 })).sent).toBe(0);
    // emptied → re-armed → full again → alert again
    await s.update('devices/bin-01', { fillPercent: 20, lastSeen: NOW });
    await runBinFullAlerts({ store: s, push, now: NOW + 7_200_000 });
    await s.update('devices/bin-01', { fillPercent: 90, lastSeen: NOW + 7_200_000 });
    expect((await runBinFullAlerts({ store: s, push, now: NOW + 7_200_000 })).sent).toBe(2);
  });

  it('skips broken, disabled and stale bins and people who turned bin notifications off', async () => {
    const s = await setup();
    const push = new MemoryPusher();
    await toggleFavBin(deps(s), ALICE, { binId: 'bin-01', on: true });
    await s.update('devices/bin-01', { fillPercent: 95, lastSeen: NOW, problem: true });
    expect((await runBinFullAlerts({ store: s, push, now: NOW })).sent).toBe(0);
    await s.update('devices/bin-01', { problem: false, lastSeen: NOW - 10 * 3_600_000 });
    expect((await runBinFullAlerts({ store: s, push, now: NOW })).sent).toBe(0);
    await s.update('devices/bin-01', { lastSeen: NOW });
    await s.set(`users/${ALICE}/prefs/notifyBins`, false);
    expect((await runBinFullAlerts({ store: s, push, now: NOW })).sent).toBe(0);
    expect(push.user).toHaveLength(0);
  });

  it('runs from the scheduler', async () => {
    const s = await setup();
    const push = new MemoryPusher();
    const r = await tick({ store: s, push }, NOW);
    expect(r.binFull).toBeDefined();
  });
});
