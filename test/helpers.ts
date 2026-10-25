import { MemoryStore } from '../src/store';
import type { Deps } from '../src/services/context';

export const SECRET = 'test-secret-not-for-production';
export const NOW = Date.UTC(2026, 2, 15, 8, 0, 0); // 12:00 in Baku
export const ALICE = 'aliceAliceAliceAlice01';
export const BOB = 'bobBobBobBobBobBobBob02';

export function deps(store: MemoryStore, now: number = NOW): Deps {
  return { store, now };
}

export async function seedUser(
  store: MemoryStore,
  uid: string,
  fields: Record<string, unknown> = {},
): Promise<void> {
  await store.set(`users/${uid}`, { name: uid.slice(0, 5), balance: 0, ...fields });
  const name = String(fields.name ?? uid.slice(0, 5));
  await store.set(`leaderboard/${uid}`, {
    name,
    nameLower: name.toLowerCase(),
    ep: Number(fields.balance ?? 0),
  });
}

export async function seedBin(store: MemoryStore, id = 'bin-01', extra = {}): Promise<void> {
  await store.set(`devices/${id}`, { name: id, fillPercent: 10, lastSeen: NOW - 1000, ...extra });
}

export const balanceOf = async (s: MemoryStore, uid: string): Promise<number> =>
  (await s.get<number>(`users/${uid}/balance`)) ?? 0;

export async function expectReason(p: Promise<unknown>, reason: string): Promise<void> {
  try {
    await p;
  } catch (e: any) {
    if (e?.reason !== reason) throw new Error(`expected reason "${reason}", got "${e?.reason ?? e}"`);
    return;
  }
  throw new Error(`expected rejection with reason "${reason}"`);
}
