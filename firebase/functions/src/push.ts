import type { Store } from './store';

export interface PushMessage {
  title: string;
  body: string;
}

/**
 * Sends push notifications. Implementations MUST be best-effort: a failed push
 * never fails (or rolls back) a money operation.
 */
export interface PushSender {
  /** Push to every registered device of one user. */
  toUser(uid: string, msg: PushMessage): Promise<void>;
  /** Push to everyone subscribed to the "news" topic. */
  toNews(msg: PushMessage): Promise<void>;
}

/** Minimal slice of firebase-admin's Messaging that we use. */
export interface MessagingLike {
  sendEachForMulticast(m: {
    tokens: string[];
    notification: { title: string; body: string };
    android?: { priority: 'high' | 'normal' };
  }): Promise<{
    responses: Array<{ success: boolean; error?: { code?: string } }>;
  }>;
  send(m: {
    topic: string;
    notification: { title: string; body: string };
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
    try {
      const rows = (await this.store.get<Record<string, { token?: string }>>(`pushTokens/${uid}`)) ?? {};
      const entries = Object.entries(rows).filter(
        ([, v]) => typeof v?.token === 'string' && v.token.length > 0,
      );
      if (entries.length === 0) return;
      const res = await this.messaging.sendEachForMulticast({
        tokens: entries.map(([, v]) => v.token as string),
        notification: { title: msg.title, body: msg.body },
        android: { priority: 'high' },
      });
      // Drop tokens FCM says are gone (app uninstalled, token rotated).
      await Promise.all(
        res.responses.map((r, i) =>
          !r.success && r.error?.code && DEAD_TOKEN_CODES.has(r.error.code)
            ? this.store.remove(`pushTokens/${uid}/${entries[i][0]}`)
            : Promise.resolve(),
        ),
      );
    } catch (e) {
      this.log('push toUser failed', e);
    }
  }

  async toNews(msg: PushMessage): Promise<void> {
    try {
      await this.messaging.send({
        topic: NEWS_TOPIC,
        notification: { title: msg.title, body: msg.body },
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
  async toNews(msg: PushMessage): Promise<void> {
    this.news.push(msg);
  }
}
