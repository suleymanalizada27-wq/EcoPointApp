import { Errors } from './errors';
import type { Deps } from './services/context';
import { createCoupon, purchaseReward, requestTransportTopUp } from './services/market';
import { redeemQr } from './services/qr';
import { lookupUsers, transferEp } from './services/transfer';
import { applyReferral, claimChallenge, claimDailyCheckIn } from './services/gamification';
import { deleteAccountData, ensureProfile, updateProfile } from './services/profile';
import { redeemDeviceWeight } from './services/devices';
import { registerPushToken, sendTestPush, unregisterPushToken } from './services/push-tokens';
import {
  adminAdjustBalance,
  adminBroadcast,
  adminDeleteReward,
  adminErrorLogs,
  adminGetUser,
  adminListTransport,
  adminLookupCoupon,
  adminOverview,
  adminRedeemCoupon,
  adminResolveTransport,
  adminSearchUsers,
  adminSetBan,
  adminSetPro,
  adminUpsertDevice,
  adminUpsertReward,
  issueBinCode,
} from './services/admin';
import { reportError } from './services/errors-report';
import { adminStats } from './services/stats';

/** Verified caller identity, built by the transport layer (HTTP / callable). */
export interface Caller {
  uid: string;
  isAdmin: boolean;
  name?: string | null;
  email?: string | null;
  photoURL?: string | null;
  /** Account creation time (ms), when known. */
  createdAt?: number;
}

export interface Ctx {
  deps: Deps;
  secret: string;
  caller: Caller;
  data: Record<string, unknown>;
  /** Looks up the account creation time lazily (needs the Admin Auth API). */
  accountCreatedAt: () => Promise<number | undefined>;
}

type Handler = (c: Ctx) => Promise<unknown>;

const admin = (c: Ctx): string => {
  if (!c.caller.isAdmin) throw Errors.forbidden();
  return c.caller.uid;
};

/** Single source of truth for every backend operation the app can call. */
export const HANDLERS: Record<string, Handler> = {
  redeemQr: (c) => redeemQr(c.deps, c.secret, c.caller.uid, c.data.payload),
  redeemDeviceWeight: (c) =>
    redeemDeviceWeight(c.deps, c.caller.uid, { deviceId: c.data.deviceId }),
  claimDailyCheckIn: (c) => claimDailyCheckIn(c.deps, c.caller.uid, c.data.day),
  claimChallenge: (c) =>
    claimChallenge(c.deps, c.caller.uid, { challengeId: c.data.challengeId, day: c.data.day }),
  applyReferral: async (c) =>
    applyReferral(c.deps, c.caller.uid, {
      code: c.data.code,
      accountCreatedAt: await c.accountCreatedAt(),
    }),
  transferEp: (c) =>
    transferEp(c.deps, c.caller.uid, {
      recipientUid: c.data.recipientUid,
      amount: c.data.amount,
      requestId: c.data.requestId,
    }),
  lookupUsers: (c) => lookupUsers(c.deps, c.caller.uid, c.data.query),
  purchaseReward: (c) =>
    purchaseReward(c.deps, c.caller.uid, {
      rewardId: c.data.rewardId,
      requestId: c.data.requestId,
    }),
  createCoupon: (c) =>
    createCoupon(c.deps, c.caller.uid, {
      partnerId: c.data.partnerId,
      ep: c.data.ep,
      requestId: c.data.requestId,
    }),
  requestTransportTopUp: (c) =>
    requestTransportTopUp(c.deps, c.caller.uid, {
      cardNumber: c.data.cardNumber,
      ep: c.data.ep,
      requestId: c.data.requestId,
    }),
  ensureProfile: (c) =>
    ensureProfile(c.deps, c.caller.uid, {
      name: c.caller.name,
      email: c.caller.email,
      photoURL: c.caller.photoURL,
    }),
  updateProfile: (c) =>
    updateProfile(c.deps, c.caller.uid, {
      name: c.data.name,
      bio: c.data.bio,
      avatar: c.data.avatar,
    }),
  deleteAccountData: (c) => deleteAccountData(c.deps, c.caller.uid),
  registerPushToken: (c) =>
    registerPushToken(c.deps, c.caller.uid, {
      token: c.data.token,
      platform: c.data.platform,
      lang: c.data.lang,
    }),
  whoami: async (c) => ({ isAdmin: c.caller.isAdmin, email: c.caller.email ?? null }),
  reportError: (c) => reportError(c.deps, c.caller.uid, c.data),
  sendTestPush: (c) => sendTestPush(c.deps, c.caller.uid),
  unregisterPushToken: (c) => unregisterPushToken(c.deps, c.caller.uid, { token: c.data.token }),

  adminAdjustBalance: (c) =>
    adminAdjustBalance(c.deps, admin(c), {
      uid: c.data.uid,
      delta: c.data.delta,
      reason: c.data.reason,
    }),
  adminBroadcast: (c) =>
    adminBroadcast(c.deps, admin(c), { title: c.data.title, body: c.data.body }),
  adminResolveTransport: (c) =>
    adminResolveTransport(c.deps, admin(c), {
      requestId: c.data.requestId,
      approve: c.data.approve,
    }),
  adminOverview: (c) => (admin(c), adminOverview(c.deps)),
  adminSearchUsers: (c) => (admin(c), adminSearchUsers(c.deps, c.data.query)),
  adminGetUser: (c) => (admin(c), adminGetUser(c.deps, c.data.uid)),
  adminSetBan: (c) =>
    adminSetBan(c.deps, admin(c), { uid: c.data.uid, banned: c.data.banned, reason: c.data.reason }),
  adminSetPro: (c) => adminSetPro(c.deps, admin(c), { uid: c.data.uid, days: c.data.days }),
  adminUpsertReward: (c) => adminUpsertReward(c.deps, admin(c), c.data),
  adminDeleteReward: (c) => adminDeleteReward(c.deps, admin(c), c.data.id),
  adminUpsertDevice: (c) => adminUpsertDevice(c.deps, admin(c), c.data),
  adminListTransport: (c) => (admin(c), adminListTransport(c.deps)),
  adminLookupCoupon: (c) => (admin(c), adminLookupCoupon(c.deps, c.data.code)),
  adminRedeemCoupon: (c) => adminRedeemCoupon(c.deps, admin(c), c.data.code),
  adminErrorLogs: (c) => (admin(c), adminErrorLogs(c.deps)),
  adminStats: (c) => (admin(c), adminStats(c.deps.store, c.deps.now)),
  adminIssueBinCode: async (c) => {
    admin(c);
    return issueBinCode(c.secret, c.data.binId, c.data.ttlSeconds, c.deps.now);
  },
};
