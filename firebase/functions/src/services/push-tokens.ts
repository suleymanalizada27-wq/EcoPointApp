import { createHash } from 'node:crypto';
import { Errors } from '../errors';
import { asLang } from '../lib/notify-text';
import type { PushReport } from '../push';
import type { Deps } from './context';
import { rateLimit } from './wallet';

const MAX_TOKENS_PER_USER = 8;
const TOKEN_RE = /^[A-Za-z0-9_:\-.]{20,4096}$/;

const key = (token: string): string =>
  createHash('sha256').update(token).digest('hex').slice(0, 32);

/** Stores an FCM device token for the caller (server-only path). */
export async function registerPushToken(
  { store, now }: Deps,
  uid: string,
  input: { token: unknown; platform?: unknown; lang?: unknown },
): Promise<{ ok: true }> {
  if (typeof input.token !== 'string' || !TOKEN_RE.test(input.token)) {
    throw Errors.invalid('Invalid token');
  }
  const platform = input.platform === 'ios' ? 'ios' : 'android';
  await rateLimit(store, `pushtoken/${uid}`, now, { windowMs: 3_600_000, max: 30 });

  const path = `pushTokens/${uid}`;
  await store.set(`${path}/${key(input.token)}`, {
    token: input.token,
    platform,
    lang: asLang(input.lang),
    ts: now,
  });
  // Small index so the scheduler can find everyone with a device.
  await store.set(`pushUsers/${uid}`, true);

  // Keep only the newest few devices.
  const all = (await store.get<Record<string, { ts?: number }>>(path)) ?? {};
  const ids = Object.keys(all);
  if (ids.length > MAX_TOKENS_PER_USER) {
    const oldest = ids
      .sort((a, b) => (all[a]?.ts ?? 0) - (all[b]?.ts ?? 0))
      .slice(0, ids.length - MAX_TOKENS_PER_USER);
    await Promise.all(oldest.map((id) => store.remove(`${path}/${id}`)));
  }
  return { ok: true };
}

/** Called on sign-out so a shared phone stops receiving the old user's pushes. */
export async function unregisterPushToken(
  { store }: Deps,
  uid: string,
  input: { token: unknown },
): Promise<{ ok: true }> {
  if (typeof input.token !== 'string' || !TOKEN_RE.test(input.token)) {
    throw Errors.invalid('Invalid token');
  }
  await store.remove(`pushTokens/${uid}/${key(input.token)}`);
  const left = await store.get<Record<string, unknown>>(`pushTokens/${uid}`);
  if (!left || Object.keys(left).length === 0) await store.remove(`pushUsers/${uid}`);
  return { ok: true };
}

/** Sends a test push to the caller's own devices and reports the outcome. */
export async function sendTestPush(
  { store, now, push }: Deps,
  uid: string,
): Promise<PushReport> {
  if (!push) throw Errors.invalid('Push is not configured on this server');
  await rateLimit(store, `pushtest/${uid}`, now, {
    windowMs: 3_600_000,
    max: 10,
    minIntervalMs: 5_000,
  });
  return push.toUserReport(uid, { title: 'EcoPoint', body: 'Test bildirisi \u2705' });
}
