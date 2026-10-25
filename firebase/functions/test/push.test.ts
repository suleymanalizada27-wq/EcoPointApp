import { beforeEach, describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { FcmPusher, MemoryPusher, type MessagingLike } from '../src/push';
import { registerPushToken, unregisterPushToken } from '../src/services/push-tokens';
import { transferEp } from '../src/services/transfer';
import { adminBroadcast } from '../src/services/admin';
import { deleteAccountData } from '../src/services/profile';
import { ALICE, BOB, NOW, expectReason, seedUser } from './helpers';

const TOKEN_A = 'tokenAAAAAAAAAAAAAAAAAAAA:APA91bExampleExampleExample1';
const TOKEN_B = 'tokenBBBBBBBBBBBBBBBBBBBB:APA91bExampleExampleExample2';

describe('push tokens', () => {
  let store: MemoryStore;
  beforeEach(() => {
    store = new MemoryStore();
  });

  it('registers a token under the caller and is idempotent', async () => {
    await registerPushToken({ store, now: NOW }, ALICE, { token: TOKEN_A });
    await registerPushToken({ store, now: NOW + 1 }, ALICE, { token: TOKEN_A });
    const rows = await store.get<Record<string, any>>(`pushTokens/${ALICE}`);
    expect(Object.keys(rows ?? {})).toHaveLength(1);
    expect(Object.values(rows!)[0].token).toBe(TOKEN_A);
  });

  it('rejects malformed tokens', async () => {
    await expectReason(registerPushToken({ store, now: NOW }, ALICE, { token: 'x' }), 'invalid-input');
    await expectReason(registerPushToken({ store, now: NOW }, ALICE, { token: 42 }), 'invalid-input');
  });

  it('keeps only the newest 8 devices', async () => {
    for (let i = 0; i < 11; i++) {
      await registerPushToken({ store, now: NOW + i }, ALICE, {
        token: `device${String(i).padStart(2, '0')}AAAAAAAAAAAAAAAAAAAAAAAA`,
      });
    }
    const rows = await store.get<Record<string, any>>(`pushTokens/${ALICE}`);
    expect(Object.keys(rows ?? {})).toHaveLength(8);
  });

  it('unregister removes the token; account deletion removes all', async () => {
    await registerPushToken({ store, now: NOW }, ALICE, { token: TOKEN_A });
    await registerPushToken({ store, now: NOW }, ALICE, { token: TOKEN_B });
    await unregisterPushToken({ store, now: NOW }, ALICE, { token: TOKEN_A });
    expect(Object.keys((await store.get(`pushTokens/${ALICE}`)) ?? {})).toHaveLength(1);
    await deleteAccountData({ store, now: NOW }, ALICE);
    expect(await store.get(`pushTokens/${ALICE}`)).toBeNull();
  });
});

describe('push delivery', () => {
  it('a transfer pushes to the recipient only', async () => {
    const store = new MemoryStore();
    const push = new MemoryPusher();
    await seedUser(store, ALICE, { balance: 100, name: 'Alice' });
    await seedUser(store, BOB, { balance: 0, name: 'Bob' });
    await transferEp({ store, now: NOW, push }, ALICE, {
      recipientUid: BOB,
      amount: 10,
      requestId: 'req-push-0001',
    });
    expect(push.user).toEqual([{ uid: BOB, title: '+10 EP', body: 'Alice' }]);
  });

  it('respects the notifyActivity preference but still stores the in-app item', async () => {
    const store = new MemoryStore();
    const push = new MemoryPusher();
    await seedUser(store, ALICE, { balance: 100, name: 'Alice' });
    await seedUser(store, BOB, { balance: 0, name: 'Bob', prefs: { notifyActivity: false } });
    await transferEp({ store, now: NOW, push }, ALICE, {
      recipientUid: BOB,
      amount: 10,
      requestId: 'req-push-0002',
    });
    expect(push.user).toHaveLength(0);
    expect(Object.keys((await store.get(`users/${BOB}/notifications`)) ?? {})).toHaveLength(1);
  });

  it('a failing push channel never breaks the transfer', async () => {
    const store = new MemoryStore();
    await seedUser(store, ALICE, { balance: 100, name: 'Alice' });
    await seedUser(store, BOB, { balance: 0, name: 'Bob' });
    const boom = {
      toUser: async () => {
        throw new Error('fcm down');
      },
      toNews: async () => {},
    };
    const r = await transferEp({ store, now: NOW, push: boom }, ALICE, {
      recipientUid: BOB,
      amount: 10,
      requestId: 'req-push-0003',
    });
    expect(r.balance).toBe(90);
  });

  it('broadcast pushes to the news topic', async () => {
    const store = new MemoryStore();
    const push = new MemoryPusher();
    await adminBroadcast({ store, now: NOW, push }, 'adminAdminAdminAdmin1', {
      title: 'Yenilik',
      body: 'Yeni mükafatlar',
    });
    expect(push.news).toEqual([{ title: 'Yenilik', body: 'Yeni mükafatlar' }]);
  });
});

describe('FcmPusher', () => {
  it('sends to every token and prunes dead ones', async () => {
    const store = new MemoryStore();
    await registerPushToken({ store, now: NOW }, ALICE, { token: TOKEN_A });
    await registerPushToken({ store, now: NOW + 1 }, ALICE, { token: TOKEN_B });
    const sent: string[][] = [];
    const messaging: MessagingLike = {
      sendEachForMulticast: async (m) => {
        sent.push(m.tokens);
        return {
          responses: m.tokens.map((t) =>
            t === TOKEN_A
              ? { success: false, error: { code: 'messaging/registration-token-not-registered' } }
              : { success: true },
          ),
        };
      },
      send: async () => 'id',
    };
    await new FcmPusher(store, messaging).toUser(ALICE, { title: 't', body: 'b' });
    expect(sent[0]).toHaveLength(2);
    const left = await store.get<Record<string, any>>(`pushTokens/${ALICE}`);
    expect(Object.values(left!).map((v) => v.token)).toEqual([TOKEN_B]);
  });

  it('does nothing (and does not throw) for a user without tokens', async () => {
    const store = new MemoryStore();
    const messaging: MessagingLike = {
      sendEachForMulticast: async () => {
        throw new Error('should not be called');
      },
      send: async () => 'id',
    };
    await expect(new FcmPusher(store, messaging).toUser(ALICE, { title: 't', body: 'b' })).resolves.toBeUndefined();
  });
});

describe('sendTestPush', () => {
  it('reports the outcome and rate-limits rapid repeats', async () => {
    const { sendTestPush } = await import('../src/services/push-tokens');
    const store = new MemoryStore();
    const push = new MemoryPusher();
    const r = await sendTestPush({ store, now: NOW, push }, ALICE);
    expect(r.sent).toBe(1);
    await expectReason(sendTestPush({ store, now: NOW + 100, push }, ALICE), 'rate-limited');
  });

  it('refuses when push is not configured', async () => {
    const { sendTestPush } = await import('../src/services/push-tokens');
    await expectReason(sendTestPush({ store: new MemoryStore(), now: NOW }, ALICE), 'invalid-input');
  });

  it('FcmPusher surfaces FCM failures in the report', async () => {
    const store = new MemoryStore();
    await registerPushToken({ store, now: NOW }, ALICE, { token: TOKEN_A });
    const messaging: MessagingLike = {
      sendEachForMulticast: async () => {
        throw new Error('Cloud Messaging API has not been used in project');
      },
      send: async () => 'id',
    };
    const r = await new FcmPusher(store, messaging).toUserReport(ALICE, { title: 't', body: 'b' });
    expect(r.tokens).toBe(1);
    expect(r.sent).toBe(0);
    expect(r.errors[0]).toContain('Cloud Messaging API');
  });
});
