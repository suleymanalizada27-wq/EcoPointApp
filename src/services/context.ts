import { randomInt } from 'node:crypto';
import type { Store } from '../store';

export interface Deps {
  store: Store;
  /** Epoch ms. Injected so tests are deterministic. */
  now: number;
}

/** Cryptographically strong [0,1) generator for codes. */
export function secureRng(): number {
  return randomInt(0, 2 ** 30) / 2 ** 30;
}
