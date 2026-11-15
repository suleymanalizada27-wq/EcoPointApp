import type { AddressInfo } from 'node:net';
import type { Server } from 'node:http';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createApp } from '../src/server';
import { MemoryStore } from '../src/store';
import { buildCode, depositMac, deviceKey } from '../src/lib/qr';
import { ALICE, BOB, NOW, SECRET, seedBin, seedUser } from './helpers';

const store = new MemoryStore();
let server: Server;
let base = '';
let clock = NOW; // advances 5 s per request so the scan rate limit does not interfere

beforeAll(async () => {
  await seedUser(store, ALICE, { balance: 500, name: 'Alice' });
  await seedUser(store, BOB, { balance: 0, name: 'Bob' });
  await seedBin(store);
  const app = createApp({
    store,
    secret: SECRET,
    now: () => (clock += 5_000),
    verifyToken: async (t) => {
      if (t === 'alice') return { uid: ALICE, isAdmin: false, name: 'Alice' };
      if (t === 'bob') return { uid: BOB, isAdmin: false };
      if (t === 'root') return { uid: 'rootRootRootRootRoot01', isAdmin: true };
      throw new Error('bad token');
    },
  });
  await new Promise<void>((r) => {
    server = app.listen(0, '127.0.0.1', () => r());
  });
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
});
afterAll(() => new Promise<void>((r) => server.close(() => r())));

async function call(name: string, body: unknown, token?: string) {
  const res = await fetch(`${base}/api/${name}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });
  return { status: res.status, json: (await res.json()) as any };
}

describe('app links file', () => {
  it('is 404 until a fingerprint is configured', async () => {
    expect((await fetch(`${base}/.well-known/assetlinks.json`)).status).toBe(404);
  });
});

describe('invite page', () => {
  it('serves a preview card for a known code and 404 for unknown/bad ones', async () => {
    await store.set('referralCodes/ABCD234', ALICE);
    await store.set(`leaderboard/${ALICE}/name`, 'Alice Aliyeva');
    const ok = await fetch(`${base}/invite/abcd-234`);
    expect(ok.status).toBe(200);
    const html = await ok.text();
    expect(html).toContain('og:image');
    expect(html).toContain('Alice səni EcoPoint-ə dəvət edir');
    expect(html).not.toContain('Aliyeva');
    expect(html).toContain('ABCD234');
    expect((await fetch(`${base}/invite/ZZZZ999`)).status).toBe(404);
    expect((await fetch(`${base}/invite/<script>`)).status).toBe(404);
  });
  it('serves the preview image', async () => {
    const r = await fetch(`${base}/og.jpg`);
    expect(r.status).toBe(200);
    expect(r.headers.get('content-type')).toContain('image/jpeg');
  });
});

describe('HTTP transport', () => {
  it('health check needs no auth', async () => {
    const r = await fetch(`${base}/health`);
    expect(r.status).toBe(200);
    expect((await r.json()).ok).toBe(true);
  });

  it('rejects missing / invalid tokens and unknown functions', async () => {
    expect((await call('openSession', {})).status).toBe(401);
    expect((await call('openSession', {}, 'forged')).status).toBe(401);
    const unknown = await call('nope', {}, 'alice');
    expect(unknown.status).toBe(404);
    expect((await call('__proto__', {}, 'alice')).status).toBe(404);
    expect((await call('constructor', {}, 'alice')).status).toBe(404);
  });

  it('transfer works end-to-end and replays are idempotent', async () => {
    const body = { recipientUid: BOB, amount: 120, requestId: 'http-req-0001' };
    const a = await call('transferEp', body, 'alice');
    expect(a.status).toBe(200);
    expect(a.json.result).toMatchObject({ balance: 380, recipientName: 'Bob' });
    const b = await call('transferEp', body, 'alice');
    expect(b.json.result).toEqual(a.json.result);
    expect(await store.get(`users/${BOB}/balance`)).toBe(120);
  });

  it('maps business errors to status + reason', async () => {
    const over = await call('transferEp', { recipientUid: BOB, amount: 9999, requestId: 'http-req-0002' }, 'alice');
    expect(over.status).toBe(412);
    expect(over.json.error).toMatchObject({ reason: 'insufficient-balance' });
    const self = await call('transferEp', { recipientUid: ALICE, amount: 1, requestId: 'http-req-0003' }, 'alice');
    expect(self.json.error.reason).toBe('self-transfer');
  });

  it('scan opens a session, the bin confirms over HTTP, the scanner is paid once', async () => {
    const before = (await store.get<number>(`users/${BOB}/balance`)) ?? 0;
    const open = await call('openSession', { payload: buildCode(SECRET, 'bin-01') }, 'bob');
    expect(open.status).toBe(200);
    const sid = open.json.result.sessionId;
    const forged = await call('openSession', { payload: buildCode('x', 'bin-01') }, 'alice');
    expect(forged.json.error.reason).toBe('invalid-qr');
    const oldFormat = await call('redeemQr', { payload: 'EP1:bin-01:n:99:abc' }, 'bob');
    expect(oldFormat.status).toBe(404);

    const post = async (body: unknown) => {
      const r = await fetch(`${base}/device/deposit`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body),
      });
      return { status: r.status, json: (await r.json()) as any };
    };
    const msg = { binId: 'bin-01', eventId: 'httpev1', grams: 300, ts: clock };
    expect((await post({ ...msg, mac: 'f'.repeat(64) })).status).toBe(403);
    const ok = await post({ ...msg, ts: clock + 5_000, mac: depositMac(deviceKey(SECRET, 'bin-01'), { ...msg, ts: clock + 5_000 }) });
    expect(ok.status).toBe(200);
    expect(ok.json.result).toMatchObject({ ep: 30 });
    const st = await call('sessionStatus', { sessionId: sid }, 'bob');
    expect(st.json.result.status).toBe('done');
    expect(await store.get(`users/${BOB}/balance`)).toBe(before + 30);
  });

  it('admin functions require the admin claim', async () => {
    const no = await call('adminBroadcast', { title: 'Hi', body: 'x' }, 'alice');
    expect(no.status).toBe(403);
    const yes = await call('adminBroadcast', { title: 'Hi', body: 'x' }, 'root');
    expect(yes.status).toBe(200);
  });

  it('survives bad JSON and non-object bodies', async () => {
    const res = await fetch(`${base}/api/lookupUsers`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: 'Bearer alice' },
      body: '{not json',
    });
    expect(res.status).toBe(400);
    const arr = await call('lookupUsers', [1, 2], 'alice');
    expect(arr.status).toBe(200);
  });
});
