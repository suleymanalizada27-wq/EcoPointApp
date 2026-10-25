import 'package:ecopoint_pro/core/utils/json_utils.dart';
import 'package:ecopoint_pro/features/marketplace/domain/reward_catalog.dart';
import 'package:ecopoint_pro/features/smart_bins/domain/smart_bin.dart';
import 'package:ecopoint_pro/features/wallet/domain/wallet_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('json_utils', () {
    test('asInt handles num, strings and junk', () {
      expect(asInt(5), 5);
      expect(asInt(5.6), 6);
      expect(asInt('1,200'), 1200);
      expect(asInt('+50'), 50);
      expect(asInt('abc', 7), 7);
      expect(asInt(null), 0);
    });
    test('asMap converts lists and maps', () {
      expect(asMap({'a': 1}), {'a': 1});
      expect(asMap([null, 'x']), {'1': 'x'});
      expect(asMap('nope'), isEmpty);
    });
  });

  group('CouponPartner', () {
    test('commission uses rounding and AZN conversion', () {
      final b = CouponPartner.all['bravo']!;
      expect(b.feeFor(1000), 50);
      expect(b.aznFor(1000), closeTo(1.9, 1e-9));
    });
  });

  group('SmartBin', () {
    final now = DateTime.fromMillisecondsSinceEpoch(2000000);
    test('no coordinates are invented', () {
      final b = SmartBin.fromMap('d1', {'name': 'Bin', 'fillPercent': 120});
      expect(b.hasCoordinates, isFalse);
      expect(b.fillPercent, 100);
      expect(b.isNearlyFull, isTrue);
      expect(b.isOnline(now), isFalse);
    });
    test('valid / invalid coordinates and online window', () {
      final ok = SmartBin.fromMap('d1', {'lat': 40.4, 'lng': 49.8, 'lastSeen': 1990000});
      expect(ok.hasCoordinates, isTrue);
      expect(ok.isOnline(now), isTrue);
      final bad = SmartBin.fromMap('d2', {'lat': 400, 'lng': 49.8, 'lastSeen': 1000});
      expect(bad.hasCoordinates, isFalse);
      expect(bad.isOnline(now), isFalse);
    });
    test('weight redeem needs weightEventId', () {
      expect(SmartBin.fromMap('d', {'weight': 5}).supportsWeightRedeem, isFalse);
      expect(SmartBin.fromMap('d', {'weightEventId': 3}).supportsWeightRedeem, isTrue);
    });
  });

  group('UserProfile', () {
    test('Pro expiry', () {
      final now = DateTime(2026, 1, 1);
      final active = UserProfile.fromMap('u', {
        'isPro': true,
        'proExpiry': DateTime(2026, 6, 1).millisecondsSinceEpoch,
      });
      final expired = UserProfile.fromMap('u', {
        'isPro': true,
        'proExpiry': DateTime(2025, 6, 1).millisecondsSinceEpoch,
      });
      expect(active.isProAt(now), isTrue);
      expect(expired.isProAt(now), isFalse);
      expect(const UserProfile(uid: 'u').isProAt(now), isFalse);
    });
    test('prefs default to enabled', () {
      final p = UserProfile.fromMap('u', {'name': 'Ana Li', 'prefs': {'notifyNews': false}});
      expect(p.notifyActivity, isTrue);
      expect(p.notifyNews, isFalse);
      expect(p.firstName, 'Ana');
    });
  });
}
