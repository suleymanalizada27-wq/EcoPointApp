import 'package:ecopoint_pro/features/wallet/domain/activity_aggregator.dart';
import 'package:ecopoint_pro/features/wallet/domain/ep_transaction.dart';
import 'package:ecopoint_pro/features/wallet/domain/impact_estimator.dart';
import 'package:ecopoint_pro/features/wallet/domain/levels.dart';
import 'package:flutter_test/flutter_test.dart';

EpTransaction tx(TxType type, int delta, DateTime t,
        {TxStatus status = TxStatus.completed}) =>
    EpTransaction(
        id: '${t.millisecondsSinceEpoch}$delta',
        type: type,
        delta: delta,
        description: '',
        time: t,
        status: status);

void main() {
  group('EpTransaction parsing (legacy + new)', () {
    test('legacy earn', () {
      final t = EpTransaction.fromMap('1', {
        'type': 'earn', 'amount': '+50', 'rawAmount': 50, 'desc': 'Scan',
        'ts': 1700000000000,
      });
      expect(t.type, TxType.earn);
      expect(t.delta, 50);
      expect(t.isEarning, isTrue);
      expect(t.status, TxStatus.completed);
    });

    test('legacy send / buy are negative', () {
      expect(EpTransaction.fromMap('1', {'type': 'snd', 'amount': '-20', 'rawAmount': 20}).delta, -20);
      expect(EpTransaction.fromMap('2', {'type': 'buy', 'rawAmount': 300}).delta, -300);
    });

    test('received is positive but not an earning', () {
      final t = EpTransaction.fromMap('1', {'type': 'received', 'amount': '+10', 'rawAmount': 10});
      expect(t.delta, 10);
      expect(t.isEarning, isFalse);
    });

    test('unknown type and status fall back safely', () {
      final t = EpTransaction.fromMap('1', {'type': '???', 'rawAmount': 5, 'status': 'pending'});
      expect(t.type, TxType.other);
      expect(t.status, TxStatus.pending);
    });

    test('numeric strings and missing fields do not throw', () {
      final t = EpTransaction.fromMap('1', {});
      expect(t.delta, 0);
      expect(t.description, '');
    });
  });

  group('Levels', () {
    test('thresholds', () {
      expect(Levels.forEarned(0).current.index, 0);
      expect(Levels.forEarned(499).current.index, 0);
      expect(Levels.forEarned(500).current.index, 1);
      expect(Levels.forEarned(25000).current.index, 5);
    });
    test('progress fraction', () {
      final p = Levels.forEarned(1250); // between 500 and 2000
      expect(p.fraction, closeTo(0.5, 1e-9));
      expect(p.next!.minEarned, 2000);
    });
    test('max level and negatives', () {
      expect(Levels.forEarned(1000000).isMax, isTrue);
      expect(Levels.forEarned(1000000).fraction, 1);
      expect(Levels.forEarned(-5).earned, 0);
    });
  });

  group('ImpactEstimator', () {
    test('scales linearly from per-scan factors', () {
      final i = ImpactEstimate.fromScans(10);
      expect(i.plasticGrams, 420);
      expect(i.co2Grams, 850);
      expect(i.waterLiters, 32);
      expect(i.energyWh, 140);
    });
    test('negative scans clamp to zero', () {
      expect(ImpactEstimate.fromScans(-3).plasticGrams, 0);
    });
  });

  group('ActivityAggregator', () {
    final now = DateTime(2026, 3, 15, 14);

    test('always returns exactly N buckets ending today', () {
      final b = ActivityAggregator.daily(const [], days: 7, now: now);
      expect(b.length, 7);
      expect(b.last.day, DateTime(2026, 3, 15));
      expect(b.first.day, DateTime(2026, 3, 9));
    });

    test('buckets earnings and purchases, ignores transfers and failures', () {
      final list = [
        tx(TxType.earn, 50, DateTime(2026, 3, 15, 9)),
        tx(TxType.weight, 20, DateTime(2026, 3, 15, 10)),
        tx(TxType.received, 100, DateTime(2026, 3, 15, 11)),
        tx(TxType.purchase, -300, DateTime(2026, 3, 14, 12)),
        tx(TxType.earn, 999, DateTime(2026, 3, 15, 13), status: TxStatus.failed),
        tx(TxType.earn, 70, DateTime(2026, 3, 1)), // outside window
      ];
      final b = ActivityAggregator.daily(list, days: 7, now: now);
      expect(b.last.earned, 70);
      expect(b[5].spent, 300);
      expect(ActivityAggregator.totalEarned(b), 70);
      expect(ActivityAggregator.totalSpent(b), 300);
    });

    test('scansOnDay counts only successful earn credits', () {
      final list = [
        tx(TxType.earn, 10, DateTime(2026, 3, 15, 8)),
        tx(TxType.earn, 10, DateTime(2026, 3, 15, 9)),
        tx(TxType.earn, 10, DateTime(2026, 3, 14, 9)),
        tx(TxType.earn, 10, DateTime(2026, 3, 15, 9), status: TxStatus.failed),
      ];
      expect(ActivityAggregator.scansOnDay(list, now), 2);
    });
  });
}
