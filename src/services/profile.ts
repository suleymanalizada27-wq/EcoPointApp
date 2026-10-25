import { CONFIG } from '../lib/config';
import { cleanText, randomCode, validAvatar, validName } from '../lib/rules';
import { Errors } from '../errors';
import type { Store } from '../store';
import type { Deps } from './context';
import { secureRng } from './context';

export interface AuthInfo {
  name?: string | null;
  email?: string | null;
  photoURL?: string | null;
}

async function syncLeaderboard(store: Store, uid: string, user: any): Promise<void> {
  const name = cleanText(user.name, CONFIG.nameMax) || '—';
  await store.update(`leaderboard/${uid}`, {
    name,
    nameLower: name.toLowerCase(),
    photoURL: typeof user.photoURL === 'string' ? user.photoURL : '',
    avatar: typeof user.avatar === 'string' ? user.avatar : '',
    ep: typeof user.balance === 'number' ? user.balance : 0,
  });
}

async function claimReferralCode(store: Store, uid: string): Promise<string> {
  for (let i = 0; i < 8; i++) {
    const code = randomCode(7, secureRng);
    const res = await store.transaction(`referralCodes/${code}`, (cur) =>
      cur === null || cur === undefined ? uid : undefined,
    );
    if (res.committed) return code;
  }
  throw new Error('Could not allocate a referral code');
}

/**
 * Idempotent. Creates / completes the server-side profile after sign-in:
 * display name, referral code (unique, indexed), zero balance and the public
 * leaderboard projection. Never overwrites an existing balance.
 */
export async function ensureProfile(
  { store, now }: Deps,
  uid: string,
  auth: AuthInfo,
): Promise<{ referralCode: string }> {
  const user = (await store.get<any>(`users/${uid}`)) ?? {};
  const updates: Record<string, unknown> = {};

  if (!user.name) {
    const fallback = (auth.email ?? '').split('@')[0];
    updates.name = cleanText(auth.name || fallback || 'EcoPoint User', CONFIG.nameMax) || 'EcoPoint User';
  }
  if (!user.email && auth.email) updates.email = auth.email;
  if (!user.photoURL && auth.photoURL) updates.photoURL = auth.photoURL;
  if (!user.createdAt) updates.createdAt = now;

  await store.transaction(`users/${uid}/balance`, (cur) =>
    cur === null || cur === undefined ? 0 : cur,
  );

  // Referral code: keep a legacy code if it is free or already ours.
  let code: string = typeof user.referralCode === 'string' ? user.referralCode : '';
  if (code) {
    const owner = await store.get<string>(`referralCodes/${code}`);
    if (owner === null) await store.set(`referralCodes/${code}`, uid);
    else if (owner !== uid) code = '';
  }
  if (!code) {
    code = await claimReferralCode(store, uid);
    updates.referralCode = code;
  }

  if (Object.keys(updates).length > 0) await store.update(`users/${uid}`, updates);
  const merged = (await store.get<any>(`users/${uid}`)) ?? {};
  await syncLeaderboard(store, uid, merged);
  return { referralCode: code };
}

export async function updateProfile(
  { store }: Deps,
  uid: string,
  input: { name: unknown; bio: unknown; avatar: unknown },
): Promise<{ ok: true }> {
  const name = cleanText(input.name, CONFIG.nameMax);
  if (!validName(name)) throw Errors.invalid('Name must be 2-40 characters');
  const bio = cleanText(input.bio, CONFIG.bioMax);
  const avatar = input.avatar ?? '';
  if (!validAvatar(avatar)) throw Errors.invalid('Invalid avatar');

  await store.update(`users/${uid}`, { name, bio, avatar });
  const merged = (await store.get<any>(`users/${uid}`)) ?? {};
  await syncLeaderboard(store, uid, merged);
  return { ok: true };
}

/** Removes the user's private data and public traces (GDPR-style erasure). */
export async function deleteAccountData({ store }: Deps, uid: string): Promise<{ ok: true }> {
  const user = await store.get<any>(`users/${uid}`);
  const code = typeof user?.referralCode === 'string' ? user.referralCode : '';
  if (code) {
    const owner = await store.get<string>(`referralCodes/${code}`);
    if (owner === uid) await store.remove(`referralCodes/${code}`);
  }
  await Promise.all([
    store.remove(`users/${uid}`),
    store.remove(`leaderboard/${uid}`),
    store.remove(`rate/${uid}`),
    store.remove(`idempotency/${uid}`),
  ]);
  return { ok: true };
}
