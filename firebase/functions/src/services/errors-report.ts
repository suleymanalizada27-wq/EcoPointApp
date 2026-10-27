import { cleanText } from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import { rateLimit } from './wallet';

/** App-side crash/error reports (Dart errors). Rate-limited and size-capped. */
export async function reportError(
  { store, now }: Deps,
  uid: string,
  input: Record<string, unknown>,
): Promise<{ ok: true }> {
  const message = cleanText(input.message, 400);
  if (!message) throw Errors.invalid('Message required');
  await rateLimit(store, `errreport/${uid}`, now, { windowMs: 3_600_000, max: 20, minIntervalMs: 2_000 });
  await store.push('errorLogs', {
    uid,
    ts: now,
    message,
    stack: cleanText(input.stack, 3000),
    app: cleanText(input.app, 20),
    platform: cleanText(input.platform, 20),
    screen: cleanText(input.screen, 60),
  });
  return { ok: true };
}
