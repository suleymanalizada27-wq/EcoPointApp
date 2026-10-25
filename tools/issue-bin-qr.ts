/**
 * Mint a signed single-use bin QR code (for provisioning / testing).
 *
 *   QR_HMAC_SECRET=... npm run qr -- bin-01 [ttlSeconds]
 *
 * The secret must equal the Firebase secret `QR_HMAC_SECRET`. Never commit it.
 */
import { issueBinCode } from '../src/services/admin';

const secret = process.env.QR_HMAC_SECRET;
const [binId, ttl] = process.argv.slice(2);
if (!secret || !binId) {
  console.error('usage: QR_HMAC_SECRET=... npm run qr -- <binId> [ttlSeconds]');
  process.exit(1);
}
const { code, expiresAt } = issueBinCode(secret, binId, ttl ? Number(ttl) : 300, Date.now());
console.log(code);
console.error(`expires ${new Date(expiresAt * 1000).toISOString()}`);
