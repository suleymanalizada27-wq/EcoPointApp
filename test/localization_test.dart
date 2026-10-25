import 'package:ecopoint_pro/app/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();

  test('az, en, ru, tr are supported with az as primary', () {
    expect(codes, containsAll(['az', 'en', 'ru', 'tr']));
    expect(AppLocalizations.primary.languageCode, 'az');
  });

  test('every language defines exactly the same keys', () {
    final base = AppLocalizations.tableFor('en').keys.toSet();
    for (final c in codes) {
      final keys = AppLocalizations.tableFor(c).keys.toSet();
      expect(base.difference(keys), isEmpty, reason: '$c is missing keys');
      expect(keys.difference(base), isEmpty, reason: '$c has extra keys');
    }
  });

  test('placeholders match across languages', () {
    final re = RegExp(r'\{(\w+)\}');
    final en = AppLocalizations.tableFor('en');
    for (final c in codes) {
      final t = AppLocalizations.tableFor(c);
      for (final e in en.entries) {
        final a = re.allMatches(e.value).map((m) => m.group(1)).toSet();
        final b = re.allMatches(t[e.key]!).map((m) => m.group(1)).toSet();
        expect(b, a, reason: '$c:${e.key}');
      }
    }
  });

  test('no empty strings', () {
    for (final c in codes) {
      AppLocalizations.tableFor(c).forEach((k, v) {
        expect(v.trim(), isNotEmpty, reason: '$c:$k');
      });
    }
  });
}
