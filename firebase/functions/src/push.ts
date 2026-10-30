import type { Store } from './store';

export interface PushMessage {
  title: string;
  body: string;
  /** In-app screen to open when the notification is tapped (whitelisted by the app). */
  route?: string;
}

/**
 * Sends push notifications. Implementations MUST be best-effort: a failed push
 * never fails (or rolls back) a money operation.
 */
export interface PushReport {
  /** Devices registered for the user. */
  tokens: number;
  sent: number;
  failed: number;
  /** FCM error codes seen (no secrets), or a top-level failure message. */
  errors: string[];
}

export interface PushSender {
  /** Push to every registered device of one user. */
  toUser(uid: string, msg: PushMessage): Promise<void>;
  /** Same, but reports what happened (used by the self-test endpoint). */
  toUserReport(uid: string, msg: PushMessage): Promise<PushReport>;
  /** Push to everyone subscribed to the "news" topic. */
  toNews(msg: PushMessage): Promise<void>;
}

/** Minimal slice of firebase-admin's Messaging that we use. */
export interface MessagingLike {
  sendEachForMulticast(m: {
    tokens: string[];
    notification: { title: string; body: string };
    data?: Record<string, string>;
    android?: { priority: 'high' | 'normal' };
  }): Promise<{
    responses: Array<{ success: boolean; error?: { code?: string } }>;
  }>;
  send(m: {
    topic: string;
    notification: { title: string; body: string };
    data?: Record<string, string>;
    android?: { priority: 'high' | 'normal' };
  }): Promise<string>;
}

export const NEWS_TOPIC = 'news';

const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** Firebase Cloud Messaging sender (free; no Blaze plan needed). */
export class FcmPusher implements PushSender {
  constructor(
    private readonly store: Store,
    private readonly messaging: MessagingLike,
    private readonly log: (m: string, e?: unknown) => void = () => {},
  ) {}

  async toUser(uid: string, msg: PushMessage): Promise<void> {
    await this.toUserReport(uid, msg);
  }

  async toUserReport(uid: string, msg: PushMessage): Promise<PushReport> {
    const report: PushReport = { tokens: 0, sent: 0, failed: 0, errors: [] };
    try {
      const rows = (await this.store.get<Record<string, { token?: string }>>(`pushTokens/${uid}`)) ?? {};
      const entries = Object.entries(rows).filter(
        ([, v]) => typeof v?.token === 'string' && v.token.length > 0,
      );
      report.tokens = entries.length;
      if (entries.length === 0) return report;
      const res = await this.messaging.sendEachForMulticast({
        tokens: entries.map(([, v]) => v.token as string),
        notification: { title: msg.title, body: msg.body },
        ...(msg.route ? { data: { route: msg.route } } : {}),
        android: { priority: 'high' },
      });
      // Drop tokens FCM says are gone (app uninstalled, token rotated).
      for (const r of res.responses) {
        if (r.success) report.sent += 1;
        else {
          report.failed += 1;
          report.errors.push(r.error?.code ?? 'unknown');
        }
      }
      await Promise.all(
        res.responses.map((r, i) =>
          !r.success && r.error?.code && DEAD_TOKEN_CODES.has(r.error.code)
            ? this.store.remove(`pushTokens/${uid}/${entries[i][0]}`)
            : Promise.resolve(),
        ),
      );
      if (res.responses.length > 0 && res.responses.every((r) => !r.success && r.error?.code && DEAD_TOKEN_CODES.has(r.error.code))) {
        await this.store.remove(`pushUsers/${uid}`);
      }
    } catch (e) {
      this.log('push toUser failed', e);
      report.errors.push(e instanceof Error ? e.message.slice(0, 300) : 'unknown');
    }
    return report;
  }

  async toNews(msg: PushMessage): Promise<void> {
    try {
      await this.messaging.send({
        topic: NEWS_TOPIC,
        notification: { title: msg.title, body: msg.body },
        ...(msg.route ? { data: { route: msg.route } } : {}),
        android: { priority: 'high' },
      });
    } catch (e) {
      this.log('push toNews failed', e);
    }
  }
}

/** Test double: records what would have been sent. */
export class MemoryPusher implements PushSender {
  readonly user: Array<{ uid: string } & PushMessage> = [];
  readonly news: PushMessage[] = [];
  async toUser(uid: string, msg: PushMessage): Promise<void> {
    this.user.push({ uid, ...msg });
  }
  async toUserReport(uid: string, msg: PushMessage): Promise<PushReport> {
    this.user.push({ uid, ...msg });
    return { tokens: 1, sent: 1, failed: 0, errors: [] };
  }
  async toNews(msg: PushMessage): Promise<void> {
    this.news.push(msg);
  }
}
