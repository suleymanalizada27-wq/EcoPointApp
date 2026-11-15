/**
 * Prints a bin's static QR payload (print it as a QR image on the bin; it never
 * expires and carries no reward) and the bin's own deposit key.
 *
 *   QR_HMAC_SECRET=... npm run qr -- bin-01
 *
 * The secret must equal the server's `QR_HMAC_SECRET`. Never commit it.
 * A bin signs each deposit message with the printed device key (see README).
 */
import { binQr } from '../src/services/admin';
import { deviceKey } from '../src/lib/qr';

const secret = process.env.QR_HMAC_SECRET;
const [binId] = process.argv.slice(2);
if (!secret || !binId) {
  console.error('usage: QR_HMAC_SECRET=... npm run qr -- <binId>');
  process.exit(1);
}
console.log(binQr(secret, binId).code);
console.error(`device key (keep secret, goes into the bin firmware): ${deviceKey(secret, binId)}`);
