import { createHmac, timingSafeEqual } from 'node:crypto';

/**
 * Smart-bin QR (static, printed on the bin):   EP2:<binId>:<signature>
 * signature = first 32 hex chars of HMAC-SHA256(secret, "EP2:<binId>").
 *
 * The code carries NO reward and never expires. Scanning only tells the
 * server "this person stands at this bin": the server opens a short
 * session, and the bin itself (authenticated with its own HMAC key)
 * confirms the deposit, which credits the person who opened the session.
 * A forged code cannot pay anything, a photographed code cannot pay unless
 * the bin really reports a deposit while that person's session is open.
 */
export const QR_PREFIX = 'EP2';
export const SIG_LENGTH = 32;

const ID = /^[A-Za-z0-9_-]{1,64}$/;
const SIG = /^[A-Fa-f0-9]{32}$/;

export interface BinCode {
  binId: string;
  sig: string;
}

const hmac = (secret: string, msg: string): string =>
  createHmac('sha256', secret).update(msg).digest('hex');

export function sign(secret: string, binId: string): string {
  return hmac(secret, `${QR_PREFIX}:${binId}`).slice(0, SIG_LENGTH);
}

export function buildCode(secret: string, binId: string): string {
  return `${QR_PREFIX}:${binId}:${sign(secret, binId)}`;
}

/** Returns null for anything that is not a well-formed bin code. */
export function parseCode(raw: unknown): BinCode | null {
  if (typeof raw !== 'string') return null;
  const s = raw.trim();
  if (s.length === 0 || s.length > 128) return null;
  const parts = s.split(':');
  if (parts.length !== 3 || parts[0] !== QR_PREFIX) return null;
  const [, binId, sig] = parts;
  if (!ID.test(binId) || !SIG.test(sig)) return null;
  return { binId, sig: sig.toLowerCase() };
}

const same = (a: string, b: string): boolean => {
  const x = Buffer.from(a, 'utf8');
  const y = Buffer.from(b, 'utf8');
  return x.length === y.length && timingSafeEqual(x, y);
};

export function verifySignature(secret: string, code: BinCode): boolean {
  return same(sign(secret, code.binId), code.sig);
}

/** Per-bin secret for the bin's own deposit messages (derived, never stored). */
export function deviceKey(secret: string, binId: string): string {
  return hmac(secret, `devkey:${binId}`);
}

export interface DepositMsg {
  binId: string;
  eventId: string;
  /** Weight in grams, or 0 when the bin has no scale. */
  grams: number;
  /** Bin clock, epoch milliseconds. */
  ts: number;
}

export function depositMac(key: string, m: DepositMsg): string {
  return hmac(key, `${m.binId}.${m.eventId}.${m.grams}.${m.ts}`);
}

export function verifyDepositMac(key: string, m: DepositMsg, mac: unknown): boolean {
  return typeof mac === 'string' && /^[A-Fa-f0-9]{64}$/.test(mac) && same(depositMac(key, m), mac.toLowerCase());
}
