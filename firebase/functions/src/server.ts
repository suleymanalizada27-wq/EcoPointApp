import express, { type Express, type NextFunction, type Request, type Response } from 'express';
import { AppError } from './errors';
import { HANDLERS, type Caller } from './handlers';
import type { PushSender } from './push';
import type { Store } from './store';

export interface ServerEnv {
  store: Store;
  secret: string;
  /** Verifies a Firebase ID token. Throws if invalid. */
  verifyToken: (token: string) => Promise<Caller>;
  /** Account creation time (ms) for the caller, if available. */
  accountCreatedAt?: (uid: string) => Promise<number | undefined>;
  /** Optional device-push channel (FCM). */
  push?: PushSender;
  now?: () => number;
  log?: (msg: string, err?: unknown) => void;
}

/**
 * HTTP transport for the backend. Every operation is `POST /api/<name>` with a
 * Firebase ID token in `Authorization: Bearer …` and a JSON body. Replies:
 *   200 {"result": …}      or      4xx/5xx {"error": {code, reason, message}}
 * Same business code and same checks as the Cloud Functions build.
 */
export function createApp(env: ServerEnv): Express {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '16kb' }));

  // Cheap endpoint used by the keep-alive pinger and the app's warm-up call.
  app.get('/health', (_req, res) => {
    res.json({ ok: true, ts: (env.now ?? Date.now)() });
  });

  app.post('/api/:name', async (req: Request, res: Response) => {
    const send = (status: number, code: string, reason: string, message: string) =>
      res.status(status).json({ error: { code, reason, message } });

    const name = String(req.params.name);
    const handler = Object.prototype.hasOwnProperty.call(HANDLERS, name) ? HANDLERS[name] : null;
    if (!handler) return send(404, 'not-found', 'unknown-function', 'Unknown function');

    const header = req.header('authorization') ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    if (!token) return send(401, 'unauthenticated', 'unauthenticated', 'Sign in required');

    let caller: Caller;
    try {
      caller = await env.verifyToken(token);
    } catch {
      return send(401, 'unauthenticated', 'unauthenticated', 'Invalid or expired token');
    }

    const data =
      req.body && typeof req.body === 'object' && !Array.isArray(req.body)
        ? (req.body as Record<string, unknown>)
        : {};

    try {
      const result = await handler({
        deps: { store: env.store, now: (env.now ?? Date.now)(), push: env.push },
        secret: env.secret,
        caller,
        data,
        accountCreatedAt: async () =>
          caller.createdAt ?? (env.accountCreatedAt ? env.accountCreatedAt(caller.uid) : undefined),
      });
      return res.json({ result });
    } catch (e) {
      if (e instanceof AppError) {
        return send(HTTP_STATUS[e.code] ?? 400, e.code, e.reason, e.message);
      }
      env.log?.(`Unhandled error in ${name}`, e);
      return send(500, 'internal', 'internal', 'Internal error');
    }
  });

  app.use((_req, res) => {
    res.status(404).json({ error: { code: 'not-found', reason: 'not-found', message: 'Not found' } });
  });
  // Body-parser errors (bad JSON, too large).
  app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
    env.log?.('Request error', err);
    res.status(400).json({ error: { code: 'invalid-argument', reason: 'invalid-input', message: 'Bad request' } });
  });
  return app;
}

const HTTP_STATUS: Record<string, number> = {
  unauthenticated: 401,
  'permission-denied': 403,
  'not-found': 404,
  'already-exists': 409,
  'failed-precondition': 412,
  'invalid-argument': 400,
  'resource-exhausted': 429,
  internal: 500,
};
