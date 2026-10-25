/** Error codes mirror Firebase `HttpsError` codes. */
export type ErrCode =
  | 'unauthenticated'
  | 'invalid-argument'
  | 'failed-precondition'
  | 'not-found'
  | 'already-exists'
  | 'resource-exhausted'
  | 'permission-denied'
  | 'internal';

/**
 * Business-rule failure. `reason` is a stable machine-readable string the
 * Flutter client maps to a localised message (see `Failure._fromFunctions`).
 */
export class AppError extends Error {
  constructor(
    public readonly code: ErrCode,
    public readonly reason: string,
    message?: string,
  ) {
    super(message ?? reason);
    this.name = 'AppError';
  }
}

export const Errors = {
  invalidQr: (m?: string) => new AppError('invalid-argument', 'invalid-qr', m),
  expiredQr: () => new AppError('failed-precondition', 'expired-qr', 'QR code expired'),
  duplicate: (m?: string) => new AppError('already-exists', 'duplicate', m),
  rateLimited: () => new AppError('resource-exhausted', 'rate-limited', 'Too many requests'),
  dailyLimit: () => new AppError('resource-exhausted', 'daily-limit', 'Daily limit reached'),
  insufficient: () => new AppError('failed-precondition', 'insufficient-balance', 'Insufficient EP'),
  outOfStock: () => new AppError('failed-precondition', 'out-of-stock', 'Out of stock'),
  selfTransfer: () => new AppError('invalid-argument', 'self-transfer', 'Cannot send to yourself'),
  notFound: (what: string) => new AppError('not-found', 'not-found', `${what} not found`),
  invalid: (m: string) => new AppError('invalid-argument', 'invalid-input', m),
  banned: () => new AppError('permission-denied', 'banned', 'Account restricted'),
  forbidden: () => new AppError('permission-denied', 'forbidden', 'Not allowed'),
};
