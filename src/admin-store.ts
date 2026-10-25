import type { Database } from 'firebase-admin/database';
import type { QueryRow, Store, TxResult } from './store';

/** Production [Store] backed by the Realtime Database Admin SDK. */
export class AdminStore implements Store {
  constructor(private readonly db: Database) {}

  async get<T = any>(path: string): Promise<T | null> {
    const snap = await this.db.ref(path).get();
    return snap.exists() ? (snap.val() as T) : null;
  }

  async set(path: string, value: unknown): Promise<void> {
    await this.db.ref(path).set(value);
  }

  async update(path: string, values: Record<string, unknown>): Promise<void> {
    await this.db.ref(path).update(values);
  }

  async remove(path: string): Promise<void> {
    await this.db.ref(path).remove();
  }

  async push(path: string, value: unknown): Promise<string> {
    const ref = this.db.ref(path).push();
    await ref.set(value);
    return ref.key as string;
  }

  async transaction(path: string, fn: (current: any) => unknown): Promise<TxResult> {
    const res = await this.db.ref(path).transaction((cur) => fn(cur) as any);
    return { committed: res.committed, value: res.snapshot.val() };
  }

  async queryByChildPrefix(
    path: string,
    child: string,
    prefix: string,
    limit: number,
  ): Promise<QueryRow[]> {
    const snap = await this.db
      .ref(path)
      .orderByChild(child)
      .startAt(prefix)
      .endAt(prefix + '')
      .limitToFirst(limit)
      .get();
    const rows: QueryRow[] = [];
    snap.forEach((c) => {
      rows.push({ key: c.key as string, value: c.val() });
    });
    return rows;
  }
}
