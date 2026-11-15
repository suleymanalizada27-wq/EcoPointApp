import { randomInt } from 'node:crypto';
import type { PushSender } from '../push';
import type { Store } from '../store';

export interface Deps {
  store: Store;
  /** Epoch ms. Injected so tests are deterministic. */
  now: number;
  /** Optional push channel (FCM in production, absent/fake in tests). */
  push?: PushSender;
  /** Virtual-bin simulator allowed (SIM_ENABLED=1). Never on in production by default. */
  sim?: boolean;
}

/** Cryptographically strong [0,1) generator for codes. */
export function secureRng(): number {
  return randomInt(0, 2 ** 30) / 2 ** 30;
}
