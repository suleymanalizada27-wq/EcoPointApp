import 'package:intl/intl.dart';

/// Number / date / distance formatting helpers.
abstract final class Fmt {
  /// 12345 → "12,345" (locale-aware grouping).
  static String number(num value, [String? locale]) =>
      NumberFormat.decimalPattern(locale).format(value);

  /// 12500 → "12.5K".
  static String compact(num value, [String? locale]) =>
      NumberFormat.compact(locale: locale).format(value);

  /// Signed amount: +50 / −120. Uses a true minus sign for typographic polish.
  static String signed(int delta, [String? locale]) {
    final abs = number(delta.abs(), locale);
    if (delta > 0) return '+$abs';
    if (delta < 0) return '−$abs';
    return abs;
  }

  /// Short distance label from metres: 640 → "640 m", 2400 → "2.4 km".
  static String distance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  /// "12 Oct, 14:05" in the given locale.
  static String dateTime(DateTime dt, [String? locale]) =>
      DateFormat('d MMM, HH:mm', locale).format(dt);

  static String date(DateTime dt, [String? locale]) =>
      DateFormat('d MMM y', locale).format(dt);

  static String weekdayShort(DateTime dt, [String? locale]) =>
      DateFormat.E(locale).format(dt);

  /// Calendar-day key (local time) such as `2026-10-20`.
  static String dayKey(DateTime dt) {
    final l = dt.toLocal();
    final m = l.month.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    return '${l.year}-$m-$d';
  }
}

/// Relative time buckets; the UI maps [unit] to a localisation key.
class RelativeTime {
  const RelativeTime(this.unit, this.value);
  final RelativeUnit unit;
  final int value;

  static RelativeTime since(DateTime then, DateTime now) {
    final diff = now.difference(then);
    final s = diff.inSeconds < 0 ? 0 : diff.inSeconds;
    if (s < 60) return RelativeTime(RelativeUnit.sec, s);
    if (s < 3600) return RelativeTime(RelativeUnit.min, s ~/ 60);
    if (s < 86400) return RelativeTime(RelativeUnit.hour, s ~/ 3600);
    return RelativeTime(RelativeUnit.day, s ~/ 86400);
  }

  String get l10nKey {
    switch (unit) {
      case RelativeUnit.sec:
        return 'ago_sec';
      case RelativeUnit.min:
        return 'ago_min';
      case RelativeUnit.hour:
        return 'ago_hour';
      case RelativeUnit.day:
        return 'ago_day';
    }
  }
}

enum RelativeUnit { sec, min, hour, day }
