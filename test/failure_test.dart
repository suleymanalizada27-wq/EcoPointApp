import 'package:ecopoint_pro/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure.fromBackend', () {
    test('maps machine-readable reasons', () {
      Failure f(String reason, [String code = 'failed-precondition']) =>
          Failure.fromBackend(400, {'code': code, 'reason': reason, 'message': 'm'});
      expect(f('insufficient-balance').code, Failure.insufficientBalance);
      expect(f('invalid-qr').code, Failure.invalidQr);
      expect(f('expired-qr').code, Failure.expiredQr);
      expect(f('duplicate', 'already-exists').code, Failure.duplicate);
      expect(f('rate-limited', 'resource-exhausted').code, Failure.rateLimited);
      expect(f('daily-limit', 'resource-exhausted').code, Failure.dailyLimit);
      expect(f('out-of-stock').code, Failure.outOfStock);
      expect(f('self-transfer', 'invalid-argument').code, Failure.selfTransfer);
    });

    test('falls back to status code when the body is not JSON', () {
      expect(Failure.fromBackend(401, null).code, Failure.unauthenticated);
      expect(Failure.fromBackend(503, null).code, Failure.network);
      expect(Failure.fromBackend(500, 'oops').code, Failure.unknown);
    });

    test('every failure maps to an existing localisation key', () {
      expect(Failure.fromBackend(412, {'reason': 'insufficient-balance'}).l10nKey,
          'transfer_err_balance');
      expect(Failure.fromBackend(500, null).l10nKey, 'error_generic');
    });
  });
}
