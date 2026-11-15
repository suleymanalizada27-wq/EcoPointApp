import { createHash } from 'node:crypto';
import { Errors } from '../errors';
import { asLang } from '../lib/notify-text';
import { dayKey } from '../lib/rules';
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
  input: { token: unknown; platform?: unknown; lang?: unknown; tz?: unknown },
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
    // Minutes east of UTC (device clock); default Baku.
    tz: typeof input.tz === 'number' && Number.isInteger(input.tz) && input.tz >= -720 && input.tz <= 840 ? input.tz : 240,
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

const ID_RE = /^[0-9A-Za-z_\-]{1,40}$/;

/** The person tapped a push: remember the day so the daily amount can adapt. */
export async function ackPush(
  { store, now }: Deps,
  uid: string,
  input: { id: unknown; kind?: unknown },
): Promise<{ ok: true }> {
  if (typeof input.id !== 'string' || !ID_RE.test(input.id)) throw Errors.invalid('Invalid id');
  await rateLimit(store, `pushack/${uid}`, now, { windowMs: 3_600_000, max: 60 });
  const day = input.id.slice(0, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) throw Errors.invalid('Invalid id');
  await store.set(`pushLog/${uid}/opens/${day}`, true);
  const kind = typeof input.kind === 'string' && /^[A-Za-z]{1,20}$/.test(input.kind) ? input.kind : null;
  if (kind) {
    await store.transaction(`pushStats/${dayKey(now)}/opened/${kind}`, (c) => (typeof c === 'number' ? c : 0) + 1);
    await store.transaction(`pushLog/${uid}/openKinds/${kind}`, (c) => (typeof c === 'number' ? c : 0) + 1);
  }
  // Keep ~2 weeks of history.
  const opens = (await store.get<Record<string, unknown>>(`pushLog/${uid}/opens`)) ?? {};
  const days = Object.keys(opens).sort();
  await Promise.all(days.slice(0, Math.max(0, days.length - 14)).map((d) => store.remove(`pushLog/${uid}/opens/${d}`)));
  return { ok: true };
}
