import { cert, initializeApp } from 'firebase-admin/app';
import { getDatabase } from 'firebase-admin/database';
import { getMessaging } from 'firebase-admin/messaging';
import { AdminStore } from './admin-store';
import { FcmPusher } from './push';
import { tick } from './scheduler';

/**
 * One-shot scheduler run (used by GitHub Actions, free, no server needed).
 * Runs every job that is due right now and exits. Safe to run in parallel
 * with the Render server: all "done" markers are claimed atomically.
 *
 * Environment: FIREBASE_SERVICE_ACCOUNT (JSON, secret) and DATABASE_URL.
 */
function need(name: string): string {
  const v = process.env[name];
  if (!v) {
    console.error(`Missing environment variable ${name}`);
    process.exit(1);
  }
  return v;
}

async function main(): Promise<void> {
  initializeApp({
    credential: cert(JSON.parse(need('FIREBASE_SERVICE_ACCOUNT'))),
    databaseURL: need('DATABASE_URL'),
  });
  const store = new AdminStore(getDatabase());
  const push = new FcmPusher(store, getMessaging(), (m, e) => console.error(m, e));
  const out = await tick({ store, push }, Date.now(), (m, e) => (e ? console.error(m, e) : console.log(m)));
  console.log('tick done', JSON.stringify(out));
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('tick failed', e);
    process.exit(1);
  });
