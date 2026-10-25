import 'package:firebase_auth/firebase_auth.dart';

/// Typed application failure. UI maps [code] to a localised message via
/// [Failure.l10nKey]; [message] is a technical fallback for logs.
class Failure implements Exception {
  const Failure(this.code, [this.message = '']);

  /// Stable machine-readable code.
  final String code;
  final String message;

  static const String network = 'network';
  static const String unauthenticated = 'unauthenticated';
  static const String backendUnavailable = 'backend-unavailable';
  static const String insufficientBalance = 'insufficient-balance';
  static const String invalidQr = 'invalid-qr';
  static const String expiredQr = 'expired-qr';
  static const String duplicate = 'duplicate';
  static const String rateLimited = 'rate-limited';
  static const String dailyLimit = 'daily-limit';
  static const String notFound = 'not-found';
  static const String outOfStock = 'out-of-stock';
  static const String invalidInput = 'invalid-input';
  static const String selfTransfer = 'self-transfer';
  static const String recentLogin = 'requires-recent-login';
  static const String unknown = 'unknown';

  /// Localisation key that best describes this failure.
  String get l10nKey {
    switch (code) {
      case network:
        return 'error_network';
      case backendUnavailable:
        return 'error_backend_unavailable';
      case insufficientBalance:
        return 'transfer_err_balance';
      case invalidQr:
        return 'scan_invalid';
      case expiredQr:
        return 'scan_expired';
      case duplicate:
        return 'scan_duplicate';
      case rateLimited:
        return 'scan_rate_limited';
      case dailyLimit:
        return 'scan_daily_limit';
      case selfTransfer:
        return 'transfer_err_self';
      case outOfStock:
        return 'reward_out_of_stock';
      case recentLogin:
        return 'auth_err_recent_login';
      case invalidInput:
        return 'transfer_err_amount';
      default:
        return 'error_generic';
    }
  }

  @override
  String toString() => 'Failure($code${message.isEmpty ? '' : ': $message'})';

  /// Converts any thrown object into a [Failure].
  static Failure from(Object error) {
    if (error is Failure) return error;
    if (error is FirebaseAuthException) return _fromAuth(error);
    if (error is FirebaseException) {
      if (error.code == 'network-error' || error.code == 'unavailable') {
        return Failure(network, error.message ?? '');
      }
      if (error.code == 'permission-denied') {
        return Failure(unauthenticated, error.message ?? '');
      }
      return Failure(unknown, error.message ?? error.code);
    }
    return Failure(unknown, error.toString());
  }

  /// Builds a failure from the backend's JSON error
  /// `{code, reason, message}` (HTTP status as a fallback).
  static Failure fromBackend(int status, Object? error) {
    String code = '';
    String? reason;
    String message = '';
    if (error is Map) {
      code = '${error['code'] ?? ''}';
      final r = error['reason'];
      if (r is String) reason = r;
      message = '${error['message'] ?? ''}';
    }
    if (code.isEmpty) {
      code = switch (status) {
        401 => 'unauthenticated',
        404 => 'not-found',
        409 => 'already-exists',
        412 => 'failed-precondition',
        429 => 'resource-exhausted',
        400 => 'invalid-argument',
        502 || 503 || 504 => 'unavailable',
        _ => 'unknown',
      };
    }
    return _fromCodeReason(code, reason, message);
  }

  static Failure _fromCodeReason(String code, String? reason, String message) {
    switch (reason) {
      case 'insufficient-balance':
        return Failure(insufficientBalance, message);
      case 'invalid-qr':
        return Failure(invalidQr, message);
      case 'expired-qr':
        return Failure(expiredQr, message);
      case 'duplicate':
        return Failure(duplicate, message);
      case 'rate-limited':
        return Failure(rateLimited, message);
      case 'daily-limit':
        return Failure(dailyLimit, message);
      case 'out-of-stock':
        return Failure(outOfStock, message);
      case 'self-transfer':
        return Failure(selfTransfer, message);
      case 'not-found':
        return Failure(notFound, message);
      case 'unknown-function':
        return Failure(backendUnavailable, message);
    }
    switch (code) {
      case 'unauthenticated':
        return Failure(unauthenticated, message);
      case 'unavailable':
      case 'deadline-exceeded':
        return Failure(network, message);
      case 'not-found':
        return Failure(notFound, message);
      case 'resource-exhausted':
        return Failure(rateLimited, message);
      case 'failed-precondition':
        return Failure(insufficientBalance, message);
      case 'invalid-argument':
        return Failure(invalidInput, message);
      case 'already-exists':
        return Failure(duplicate, message);
      default:
        return Failure(unknown, message.isEmpty ? code : message);
    }
  }

  static Failure _fromAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return Failure(network, e.message ?? '');
      case 'requires-recent-login':
        return Failure(recentLogin, e.message ?? '');
      default:
        return Failure(e.code, e.message ?? '');
    }
  }
}
