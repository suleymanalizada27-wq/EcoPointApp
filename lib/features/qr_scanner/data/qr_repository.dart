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

class QrRepository {
  QrRepository(this._backend);
  final BackendService _backend;

  /// Sends the raw QR to the backend. **EP are only credited if the server
  /// verifies the signature, expiry, single-use nonce, rate limits and daily
  /// cap.** The client never decides the amount.
  Future<QrRedeemResult> redeem(QrPayload payload) async {
    final res = await _backend.call('redeemQr', {'payload': payload.raw});
    return QrRedeemResult(
      ep: asInt(res['ep']),
      baseEp: asInt(res['baseEp']),
      multiplier: asInt(res['multiplier'], 1),
      balance: asInt(res['balance']),
      binId: asString(res['binId']),
    );
  }
}

final qrRepositoryProvider = Provider<QrRepository>(
  (ref) => QrRepository(ref.watch(backendServiceProvider)),
);
