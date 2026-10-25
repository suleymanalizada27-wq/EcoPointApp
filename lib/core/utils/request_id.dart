import 'dart:math';

/// Generates a random idempotency key (32 hex chars).
///
/// Every state-changing callable receives one. The backend records it inside
/// the same atomic operation, so a retry after a timeout or a double-tap can
/// never apply the same transfer / purchase twice.
String newRequestId() {
  final rnd = Random.secure();
  final buf = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buf.write(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}
