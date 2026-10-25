/**
 * Minimal database abstraction so the money-handling logic can be unit
 * tested against an in-memory implementation and run in production against
 * the Firebase Realtime Database (Admin SDK).
 */
export interface TxResult {
  committed: boolean;
  value: unknown;
}

export interface QueryRow {
  key: string;
  value: any;
}

export interface Store {
  get<T = any>(path: string): Promise<T | null>;
  set(path: string, value: unknown): Promise<void>;
  /** Multi-path update relative to `path`; a `null` value deletes. */
  update(path: string, values: Record<string, unknown>): Promise<void>;
  remove(path: string): Promise<void>;
  push(path: string, value: unknown): Promise<string>;
  /**
   * Atomic read-modify-write. `fn` may be invoked several times and MUST
   * tolerate `null`. Returning `undefined` aborts the transaction.
   */
  transaction(path: string, fn: (current: any) => unknown): Promise<TxResult>;
  /** Children of `path` whose `child` string starts with `prefix`. */
  queryByChildPrefix(
    path: string,
    child: string,
    prefix: string,
    limit: number,
  ): Promise<QueryRow[]>;
}

// ───────────────────────── in-memory (tests / emulation) ─────────────────────

function split(path: string): string[] {
  return path.split('/').filter((p) => p.length > 0);
}

function clone<T>(v: T): T {
  return v === undefined ? v : (JSON.parse(JSON.stringify(v)) as T);
}

export class MemoryStore implements Store {
  private root: Record<string, any> = {};
  private pushCounter = 0;

  /** Test helper: peek at the raw tree. */
  dump(): Record<string, any> {
    return clone(this.root);
  }

  private read(path: string): any {
    let cur: any = this.root;
    for (const seg of split(path)) {
      if (cur === null || typeof cur !== 'object' || !(seg in cur)) return null;
      cur = cur[seg];
    }
    return cur === undefined ? null : cur;
  }

  private write(path: string, value: unknown): void {
    const segs = split(path);
    if (segs.length === 0) {
      this.root = (clone(value) as Record<string, any>) ?? {};
      return;
    }
    let cur: any = this.root;
    for (let i = 0; i < segs.length - 1; i++) {
      const s = segs[i];
      if (cur[s] === null || typeof cur[s] !== 'object') cur[s] = {};
      cur = cur[s];
    }
    const last = segs[segs.length - 1];
    if (value === null || value === undefined) {
      delete cur[last];
      this.prune(segs);
    } else {
      cur[last] = clone(value);
    }
  }

  /** RTDB drops empty parents; mimic that. */
  private prune(segs: string[]): void {
    for (let n = segs.length - 1; n > 0; n--) {
      const parent = this.read(segs.slice(0, n).join('/'));
      if (parent && typeof parent === 'object' && Object.keys(parent).length === 0) {
        const grand = this.read(segs.slice(0, n - 1).join('/') || '/');
        if (n - 1 === 0) delete this.root[segs[0]];
        else if (grand) delete grand[segs[n - 1]];
      } else break;
    }
  }

  async get<T = any>(path: string): Promise<T | null> {
    return clone(this.read(path)) as T | null;
  }

  async set(path: string, value: unknown): Promise<void> {
    this.write(path, value);
  }

  async update(path: string, values: Record<string, unknown>): Promise<void> {
    for (const [k, v] of Object.entries(values)) {
      this.write(`${path}/${k}`, v);
    }
  }

  async remove(path: string): Promise<void> {
    this.write(path, null);
  }

  async push(path: string, value: unknown): Promise<string> {
    this.pushCounter += 1;
    const key = `-M${Date.now().toString(36)}${this.pushCounter.toString(36).padStart(6, '0')}`;
    this.write(`${path}/${key}`, value);
    return key;
  }

  async transaction(path: string, fn: (current: any) => unknown): Promise<TxResult> {
    const current = clone(this.read(path));
    const next = fn(current);
    if (next === undefined) return { committed: false, value: current };
    this.write(path, next);
    return { committed: true, value: clone(next) };
  }

  async queryByChildPrefix(
    path: string,
    child: string,
    prefix: string,
    limit: number,
  ): Promise<QueryRow[]> {
    const node = this.read(path);
    if (!node || typeof node !== 'object') return [];
    const rows: QueryRow[] = [];
    for (const [key, value] of Object.entries(node)) {
      const v = (value as any)?.[child];
      if (typeof v === 'string' && v.startsWith(prefix)) {
        rows.push({ key, value: clone(value) });
      }
    }
    rows.sort((a, b) => String(a.value[child]).localeCompare(String(b.value[child])));
    return rows.slice(0, limit);
  }
}
