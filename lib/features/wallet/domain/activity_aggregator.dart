import 'ep_transaction.dart';

/// EP movement for one calendar day (local time).
class DayBucket {
  const DayBucket({
    required this.day,
    required this.earned,
    required this.spent,
  });

  /// Local midnight of the day.
  final DateTime day;

  /// Credits from recycling activity (scans, weight, bonuses).
  final int earned;

  /// Debits from purchases / coupons.
  final int spent;
}

/// Pure aggregation of transactions into per-day buckets. Used by the home
/// 7-day chart and the statistics screen, and unit-tested.
abstract final class ActivityAggregator {
  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns exactly [days] buckets, oldest → newest, ending on [now]'s day.
  static List<DayBucket> daily(
    List<EpTransaction> txs, {
    required int days,
    required DateTime now,
  }) {
    final today = _midnight(now);
    final earned = List<int>.filled(days, 0);
    final spent = List<int>.filled(days, 0);

    for (final tx in txs) {
      if (tx.status == TxStatus.failed) continue;
      final diff = today.difference(_midnight(tx.time)).inDays;
      if (diff < 0 || diff >= days) continue;
      final idx = days - 1 - diff;
      if (tx.isEarning) {
        earned[idx] += tx.absolute;
      } else if (tx.type == TxType.purchase && tx.delta < 0) {
        spent[idx] += tx.absolute;
      }
    }

    return List<DayBucket>.generate(
      days,
      (i) => DayBucket(
        day: today.subtract(Duration(days: days - 1 - i)),
        earned: earned[i],
        spent: spent[i],
      ),
    );
  }

  static int totalEarned(List<DayBucket> b) =>
      b.fold<int>(0, (a, e) => a + e.earned);

  static int totalSpent(List<DayBucket> b) =>
      b.fold<int>(0, (a, e) => a + e.spent);

  /// Number of scan-type earnings on [day] (used by daily missions UI).
  static int scansOnDay(List<EpTransaction> txs, DateTime day) {
    final target = _midnight(day);
    return txs
        .where((t) =>
            t.type == TxType.earn &&
            t.isCredit &&
            t.status != TxStatus.failed &&
            _midnight(t.time) == target)
        .length;
  }
}
