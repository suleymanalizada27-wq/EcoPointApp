import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getDatabase } from 'firebase-admin/database';
import { getMessaging } from 'firebase-admin/messaging';
import { AdminStore } from './admin-store';
import { isAdminToken, parseAdminEmails } from './admin-access';
import { FcmPusher } from './push';
import { startScheduler } from './scheduler';
import { createApp } from './server';

/**
 * Production entry point (Render / any Node host).
 *
 * Environment:
 *   FIREBASE_SERVICE_ACCOUNT  service-account JSON (one line) — keep secret
 *   DATABASE_URL              https://<project>-default-rtdb.<region>.firebasedatabase.app
 *   QR_HMAC_SECRET            HMAC key for bin QR codes — keep secret
 *   PORT                      provided by the host
 */
function need(name: string): string {
  const v = process.env[name];
  if (!v) {
    console.error(`Missing environment variable ${name}`);
    process.exit(1);
  }
  return v;
}

const account = JSON.parse(need('FIREBASE_SERVICE_ACCOUNT'));
initializeApp({ credential: cert(account), databaseURL: need('DATABASE_URL') });

const adminEmails = parseAdminEmails(process.env.ADMIN_EMAILS);
const store = new AdminStore(getDatabase());
const push = new FcmPusher(store, getMessaging(), (m, e) => console.error(m, e));
const app = createApp({
  store,
  push,
  contactEmail: process.env.CONTACT_EMAIL ?? [...adminEmails][0],
  downloadUrl: process.env.APP_DOWNLOAD_URL || undefined,
  publicUrl: process.env.PUBLIC_URL || process.env.RENDER_EXTERNAL_URL || undefined,
  secret: need('QR_HMAC_SECRET'),
  verifyToken: async (token) => {
    const d = await getAuth().verifyIdToken(token);
    return {
      uid: d.uid,
      isAdmin: isAdminToken(d, adminEmails),
      name: typeof d.name === 'string' ? d.name : null,
      email: d.email ?? null,
      photoURL: typeof d.picture === 'string' ? d.picture : null,
    };
  },
  accountCreatedAt: async (uid) => {
    const t = Date.parse((await getAuth().getUser(uid)).metadata.creationTime);
    return Number.isNaN(t) ? undefined : t;
  },
  log: (m, e) => console.error(m, e),
});

const port = Number(process.env.PORT ?? 8080);
app.listen(port, '0.0.0.0', () => console.log(`EcoPoint API listening on ${port}`));
// Daily reminders / weekly summary (needs the server awake: UptimeRobot pings /health).
startScheduler({ store, push }, (m, e) => (e ? console.error(m, e) : console.log(m)));
