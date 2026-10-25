import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getDatabase } from 'firebase-admin/database';
import { logger } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { AdminStore } from './admin-store';
import { AppError } from './errors';
import type { Deps } from './services/context';
import { createCoupon as svc_createCoupon, purchaseReward as svc_purchaseReward, requestTransportTopUp as svc_requestTransportTopUp } from './services/market';
import { redeemQr as svc_redeemQr } from './services/qr';
import { lookupUsers as svc_lookupUsers, transferEp as svc_transferEp } from './services/transfer';
import {
  applyReferral as svc_applyReferral,
  claimChallenge as svc_claimChallenge,
  claimDailyCheckIn as svc_claimDailyCheckIn,
} from './services/gamification';
import { deleteAccountData as svc_deleteAccountData, ensureProfile as svc_ensureProfile, updateProfile as svc_updateProfile } from './services/profile';
import { redeemDeviceWeight as svc_redeemDeviceWeight } from './services/devices';
import {
  adminAdjustBalance as svc_adminAdjustBalance,
  adminBroadcast as svc_adminBroadcast,
  adminResolveTransport as svc_adminResolveTransport,
  issueBinCode as svc_issueBinCode,
} from './services/admin';

initializeApp();

/** HMAC key for bin QR codes: `firebase functions:secrets:set QR_HMAC_SECRET` */
const QR_HMAC_SECRET = defineSecret('QR_HMAC_SECRET');

const REGION = 'us-central1';
const base = { region: REGION, cors: false, maxInstances: 20 } as const;

function deps(): Deps {
  return { store: new AdminStore(getDatabase()), now: Date.now() };
}

function requireUid(req: CallableRequest): string {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');
  return uid;
}

function requireAdmin(req: CallableRequest): string {
  const uid = requireUid(req);
  if (req.auth?.token?.admin !== true) {
    throw new HttpsError('permission-denied', 'Admin only', { reason: 'forbidden' });
  }
  return uid;
}

/** Maps business errors to HttpsError (with a machine-readable `reason`). */
async function run<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    if (e instanceof AppError) {
      throw new HttpsError(e.code, e.message, { reason: e.reason });
    }
    logger.error('Unhandled backend error', e);
    throw new HttpsError('internal', 'Internal error');
  }
}

const data = (req: CallableRequest): Record<string, unknown> =>
  req.data && typeof req.data === 'object' ? (req.data as Record<string, unknown>) : {};

// ───────────────────────────── earning ─────────────────────────────

export const redeemQr = onCall({ ...base, secrets: [QR_HMAC_SECRET] }, (req) =>
  run(() => svc_redeemQr(deps(), QR_HMAC_SECRET.value(), requireUid(req), data(req).payload)),
);

export const redeemDeviceWeight = onCall(base, (req) =>
  run(() => svc_redeemDeviceWeight(deps(), requireUid(req), { deviceId: data(req).deviceId })),
);

export const claimDailyCheckIn = onCall(base, (req) =>
  run(() => svc_claimDailyCheckIn(deps(), requireUid(req), data(req).day)),
);

export const claimChallenge = onCall(base, (req) =>
  run(() =>
    svc_claimChallenge(deps(), requireUid(req), {
      challengeId: data(req).challengeId,
      day: data(req).day,
    }),
  ),
);

export const applyReferral = onCall(base, (req) =>
  run(async () => {
    const uid = requireUid(req);
    const user = await getAuth().getUser(uid);
    const created = Date.parse(user.metadata.creationTime);
    return svc_applyReferral(deps(), uid, {
      code: data(req).code,
      accountCreatedAt: Number.isNaN(created) ? undefined : created,
    });
  }),
);

// ───────────────────────────── spending / transfers ─────────────────────────────

export const transferEp = onCall(base, (req) =>
  run(() =>
    svc_transferEp(deps(), requireUid(req), {
      recipientUid: data(req).recipientUid,
      amount: data(req).amount,
      requestId: data(req).requestId,
    }),
  ),
);

export const lookupUsers = onCall(base, (req) =>
  run(() => svc_lookupUsers(deps(), requireUid(req), data(req).query)),
);

export const purchaseReward = onCall(base, (req) =>
  run(() =>
    svc_purchaseReward(deps(), requireUid(req), {
      rewardId: data(req).rewardId,
      requestId: data(req).requestId,
    }),
  ),
);

export const createCoupon = onCall(base, (req) =>
  run(() =>
    svc_createCoupon(deps(), requireUid(req), {
      partnerId: data(req).partnerId,
      ep: data(req).ep,
      requestId: data(req).requestId,
    }),
  ),
);

export const requestTransportTopUp = onCall(base, (req) =>
  run(() =>
    svc_requestTransportTopUp(deps(), requireUid(req), {
      cardNumber: data(req).cardNumber,
      ep: data(req).ep,
      requestId: data(req).requestId,
    }),
  ),
);

// ───────────────────────────── profile / account ─────────────────────────────

export const ensureProfile = onCall(base, (req) =>
  run(async () => {
    const uid = requireUid(req);
    const user = await getAuth().getUser(uid);
    return svc_ensureProfile(deps(), uid, {
      name: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
    });
  }),
);

export const updateProfile = onCall(base, (req) =>
  run(() =>
    svc_updateProfile(deps(), requireUid(req), {
      name: data(req).name,
      bio: data(req).bio,
      avatar: data(req).avatar,
    }),
  ),
);

export const deleteAccountData = onCall(base, (req) =>
  run(() => svc_deleteAccountData(deps(), requireUid(req))),
);

// ───────────────────────────── admin ─────────────────────────────

export const adminAdjustBalance = onCall(base, (req) =>
  run(() =>
    svc_adminAdjustBalance(deps(), requireAdmin(req), {
      uid: data(req).uid,
      delta: data(req).delta,
      reason: data(req).reason,
    }),
  ),
);

export const adminBroadcast = onCall(base, (req) =>
  run(() =>
    svc_adminBroadcast(deps(), requireAdmin(req), {
      title: data(req).title,
      body: data(req).body,
    }),
  ),
);

export const adminResolveTransport = onCall(base, (req) =>
  run(() =>
    svc_adminResolveTransport(deps(), requireAdmin(req), {
      requestId: data(req).requestId,
      approve: data(req).approve,
    }),
  ),
);

export const adminIssueBinCode = onCall({ ...base, secrets: [QR_HMAC_SECRET] }, (req) =>
  run(async () => {
    requireAdmin(req);
    return svc_issueBinCode(QR_HMAC_SECRET.value(), data(req).binId, data(req).ttlSeconds, Date.now());
  }),
);

// ───────────────────────────── housekeeping ─────────────────────────────

/** Removes expired QR nonces and old idempotency / rate records daily. */
export const pruneExpired = onSchedule(
  { region: REGION, schedule: 'every 24 hours', timeZone: 'Asia/Baku' },
  async () => {
    const db = getDatabase();
    const nowSec = Math.floor(Date.now() / 1000);

    // QR codes are single-use and expire, so a nonce past `exp` can never be
    // replayed (the signature check rejects it first).
    const nonces = await db
      .ref('qrNonces')
      .orderByChild('exp')
      .endAt(nowSec - 86_400)
      .get();
    const updates: Record<string, null> = {};
    nonces.forEach((c) => {
      updates[`qrNonces/${c.key}`] = null;
    });
    if (Object.keys(updates).length > 0) await db.ref().update(updates);
    logger.info(`pruned ${Object.keys(updates).length} expired QR nonces`);
  },
);
