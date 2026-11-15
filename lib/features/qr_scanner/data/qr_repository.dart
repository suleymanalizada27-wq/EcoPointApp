import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/backend_service.dart';
import '../../../core/utils/json_utils.dart';
import '../../../core/utils/qr_payload.dart';

class QrRedeemResult {
  const QrRedeemResult({
    required this.ep,
    required this.baseEp,
    required this.multiplier,
    required this.balance,
    required this.binId,
  });

  final int ep;
  final int baseEp;
  final int multiplier;
  final int balance;
  final String binId;
}

/// A scan opened a short session at a bin. Nothing is paid yet.
class QrSession {
  const QrSession({
    required this.sessionId,
    required this.binId,
    required this.binName,
    required this.expiresAt,
  });

  final String sessionId;
  final String binId;
  final String binName;
  final DateTime expiresAt;
}

enum QrSessionState { open, done, failed, cancelled, expired }

class QrSessionStatus {
  const QrSessionStatus(this.state, {this.result, this.reason});
  final QrSessionState state;
  final QrRedeemResult? result;
  final String? reason;
}

class QrRepository {
  QrRepository(this._backend);
  final BackendService _backend;

  /// Tells the server which bin the person stands at. **No EP are credited
  /// here**: the bin confirms the deposit itself and the server pays the
  /// person whose session is open (signature, limits and caps are server-side).
  Future<QrSession> open(QrPayload payload) async {
    final res = await _backend.call('openSession', {'payload': payload.raw});
    return QrSession(
      sessionId: asString(res['sessionId']),
      binId: asString(res['binId']),
      binName: asString(res['binName']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(asInt(res['expiresAt'])),
    );
  }

  Future<QrSessionStatus> status(QrSession s) async {
    final res = await _backend.call('sessionStatus', {'sessionId': s.sessionId});
    final state = switch (asString(res['status'])) {
      'done' => QrSessionState.done,
      'failed' => QrSessionState.failed,
      'cancelled' => QrSessionState.cancelled,
      'expired' => QrSessionState.expired,
      _ => QrSessionState.open,
    };
    QrRedeemResult? result;
    final r = res['result'];
    if (state == QrSessionState.done && r is Map) {
      result = QrRedeemResult(
        ep: asInt(r['ep']),
        baseEp: asInt(r['baseEp']),
        multiplier: asInt(r['multiplier'], 1),
        balance: asInt(r['balance']),
        binId: asString(res['binId']),
      );
    }
    return QrSessionStatus(state,
        result: result, reason: res['reason'] as String?);
  }

  Future<void> cancel(QrSession s) async {
    try {
      await _backend.call('cancelSession', {'sessionId': s.sessionId});
    } catch (_) {}
  }
}

final qrRepositoryProvider = Provider<QrRepository>(
  (ref) => QrRepository(ref.watch(backendServiceProvider)),
);
