/// Parsing of EcoPoint QR payloads.
///
/// This is **format detection only**. It never grants anything: EP are only
/// awarded by the `redeemQr` Cloud Function after verifying the HMAC
/// signature, expiry and single-use nonce on the server.
///
/// Supported formats:
///  * Smart-bin code:  `EP1:<binId>:<nonce>:<expiresAtUnixSeconds>:<signature>`
///  * User code:       `ecopoint:user:<uid>` (also a bare Firebase UID, which
///    is what the legacy web app displayed as "My QR")
enum QrKind { bin, user, invalid }

class QrPayload {
  const QrPayload._(this.kind, this.raw,
      {this.binId, this.nonce, this.expiresAt, this.userId});

  final QrKind kind;
  final String raw;
  final String? binId;
  final String? nonce;

  /// Expiry as a UTC timestamp (bin codes only).
  final DateTime? expiresAt;
  final String? userId;

  bool get isBin => kind == QrKind.bin;
  bool get isUser => kind == QrKind.user;
  bool get isValid => kind != QrKind.invalid;

  /// Client-side hint only; the server re-checks authoritatively.
  bool isExpired(DateTime now) {
    final e = expiresAt;
    return e != null && !now.toUtc().isBefore(e);
  }

  static const String binPrefix = 'EP1';
  static const String userPrefix = 'ecopoint:user:';

  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static final RegExp _sig = RegExp(r'^[A-Fa-f0-9]{16,64}$');
  static final RegExp _uid = RegExp(r'^[A-Za-z0-9]{20,40}$');

  static QrPayload parse(String? input) {
    final raw = (input ?? '').trim();
    if (raw.isEmpty || raw.length > 256) {
      return QrPayload._(QrKind.invalid, raw);
    }

    if (raw.startsWith('$binPrefix:')) {
      final parts = raw.split(':');
      if (parts.length != 5) return QrPayload._(QrKind.invalid, raw);
      final binId = parts[1];
      final nonce = parts[2];
      final exp = int.tryParse(parts[3]);
      final sig = parts[4];
      if (!_id.hasMatch(binId) ||
          !_id.hasMatch(nonce) ||
          exp == null ||
          exp <= 0 ||
          !_sig.hasMatch(sig)) {
        return QrPayload._(QrKind.invalid, raw);
      }
      return QrPayload._(
        QrKind.bin,
        raw,
        binId: binId,
        nonce: nonce,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
      );
    }

    if (raw.startsWith(userPrefix)) {
      final uid = raw.substring(userPrefix.length);
      if (_uid.hasMatch(uid)) {
        return QrPayload._(QrKind.user, raw, userId: uid);
      }
      return QrPayload._(QrKind.invalid, raw);
    }

    if (_uid.hasMatch(raw)) {
      return QrPayload._(QrKind.user, raw, userId: raw);
    }

    return QrPayload._(QrKind.invalid, raw);
  }

  /// Payload encoded in a user's own "My QR".
  static String forUser(String uid) => '$userPrefix$uid';
}
