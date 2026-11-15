/// Parsing of EcoPoint QR payloads.
///
/// This is **format detection only**. It never grants anything: scanning a bin
/// only asks the server to open a short session; EP are credited when the bin
/// itself confirms the deposit (verified by the server with the bin's key).
///
/// Supported formats:
///  * Smart-bin code (static, printed on the bin): `EP2:<binId>:<signature>`
///  * User code:       `ecopoint:user:<uid>` (also a bare Firebase UID, which
///    is what the legacy web app displayed as "My QR")
enum QrKind { bin, user, invalid }

class QrPayload {
  const QrPayload._(this.kind, this.raw, {this.binId, this.userId});

  final QrKind kind;
  final String raw;
  final String? binId;
  final String? userId;

  bool get isBin => kind == QrKind.bin;
  bool get isUser => kind == QrKind.user;
  bool get isValid => kind != QrKind.invalid;

  static const String binPrefix = 'EP2';
  static const String userPrefix = 'ecopoint:user:';

  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static final RegExp _sig = RegExp(r'^[A-Fa-f0-9]{32}$');
  static final RegExp _uid = RegExp(r'^[A-Za-z0-9]{20,40}$');

  static QrPayload parse(String? input) {
    final raw = (input ?? '').trim();
    if (raw.isEmpty || raw.length > 256) {
      return QrPayload._(QrKind.invalid, raw);
    }

    if (raw.startsWith('$binPrefix:')) {
      final parts = raw.split(':');
      if (parts.length != 3) return QrPayload._(QrKind.invalid, raw);
      final binId = parts[1];
      final sig = parts[2];
      if (!_id.hasMatch(binId) || !_sig.hasMatch(sig)) {
        return QrPayload._(QrKind.invalid, raw);
      }
      return QrPayload._(QrKind.bin, raw, binId: binId);
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
