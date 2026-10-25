import { createHmac, timingSafeEqual } from 'node:crypto';

/**
 * Smart-bin QR format:  EP1:<binId>:<nonce>:<expiresAtUnixSeconds>:<signature>
 * signature = first 32 hex chars of HMAC-SHA256(secret, "<binId>:<nonce>:<exp>").
 *
 * Only a holder of the secret (the backend, or a bin firmware provisioned
 * with it) can mint valid codes, so the app can never be tricked into paying
 * EP for an arbitrary string.
 */
export const QR_PREFIX = 'EP1';
export const SIG_LENGTH = 32;

const ID = /^[A-Za-z0-9_-]{1,64}$/;
const SIG = /^[A-Fa-f0-9]{32}$/;

export interface BinCode {
  binId: string;
  nonce: string;
  exp: number; // unix seconds
  sig: string;
}

export function sign(secret: string, binId: string, nonce: string, exp: number): string {
  return createHmac('sha256', secret)
    .update(`${binId}:${nonce}:${exp}`)
    .digest('hex')
    .slice(0, SIG_LENGTH);
}

export function buildCode(secret: string, binId: string, nonce: string, exp: number): string {
  return `${QR_PREFIX}:${binId}:${nonce}:${exp}:${sign(secret, binId, nonce, exp)}`;
}

/** Returns null for anything that is not a well-formed bin code. */
export function parseCode(raw: unknown): BinCode | null {
  if (typeof raw !== 'string') return null;
  const s = raw.trim();
  if (s.length === 0 || s.length > 256) return null;
  const parts = s.split(':');
  if (parts.length !== 5 || parts[0] !== QR_PREFIX) return null;
  const [, binId, nonce, expStr, sig] = parts;
  if (!ID.test(binId) || !ID.test(nonce) || !SIG.test(sig)) return null;
  if (!/^\d{1,12}$/.test(expStr)) return null;
  const exp = Number(expStr);
  if (!Number.isSafeInteger(exp) || exp <= 0) return null;
  return { binId, nonce, exp, sig: sig.toLowerCase() };
}

export function verifySignature(secret: string, code: BinCode): boolean {
  const expected = Buffer.from(sign(secret, code.binId, code.nonce, code.exp), 'utf8');
  const given = Buffer.from(code.sig, 'utf8');
  return expected.length === given.length && timingSafeEqual(expected, given);
}
