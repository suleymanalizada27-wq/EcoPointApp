import '../../../core/utils/json_utils.dart';

enum TxType { earn, received, sent, purchase, weight, bonus, other }

enum TxStatus { completed, pending, failed }

/// One entry in `users/{uid}/transactions`.
///
/// Reads both the legacy web-app format
/// (`{type:'earn', amount:'+50', rawAmount:50, desc, ts, date}`) and entries
/// written by the new backend (same fields plus `status`).
class EpTransaction {
  const EpTransaction({
    required this.id,
    required this.type,
    required this.delta,
    required this.description,
    required this.time,
    this.status = TxStatus.completed,
  });

  final String id;
  final TxType type;

  /// Signed EP change: positive = credited, negative = debited.
  final int delta;
  final String description;
  final DateTime time;
  final TxStatus status;

  bool get isCredit => delta > 0;
  int get absolute => delta.abs();

  /// Money that came from recycling activity (not transfers / refunds).
  bool get isEarning =>
      isCredit &&
      (type == TxType.earn || type == TxType.weight || type == TxType.bonus);

  static TxType parseType(String? raw) {
    switch (raw) {
      case 'earn':
        return TxType.earn;
      case 'received':
        return TxType.received;
      case 'snd':
      case 'sent':
        return TxType.sent;
      case 'buy':
      case 'purchase':
        return TxType.purchase;
      case 'weight':
        return TxType.weight;
      case 'bonus':
        return TxType.bonus;
      default:
        return TxType.other;
    }
  }

  static TxStatus parseStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return TxStatus.pending;
      case 'failed':
        return TxStatus.failed;
      default:
        return TxStatus.completed;
    }
  }

  /// Computes the signed delta from legacy fields.
  static int parseDelta(TxType type, Object? amount, Object? rawAmount) {
    final raw = asInt(rawAmount).abs();
    final amountStr = asString(amount).trim();
    if (amountStr.startsWith('-')) {
      return -(raw != 0 ? raw : asInt(amountStr).abs());
    }
    if (amountStr.startsWith('+')) {
      return raw != 0 ? raw : asInt(amountStr).abs();
    }
    final magnitude = raw != 0 ? raw : asInt(amount).abs();
    final negative = type == TxType.sent || type == TxType.purchase;
    return negative ? -magnitude : magnitude;
  }

  factory EpTransaction.fromMap(String id, Map<String, Object?> m) {
    final type = parseType(asString(m['type']));
    return EpTransaction(
      id: id,
      type: type,
      delta: parseDelta(type, m['amount'], m['rawAmount']),
      description: asString(m['desc']),
      time: DateTime.fromMillisecondsSinceEpoch(asInt(m['ts']), isUtc: false),
      status: parseStatus(asString(m['status'])),
    );
  }
}
