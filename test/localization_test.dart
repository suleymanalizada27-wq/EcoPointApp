import 'package:ecopoint_pro/app/localization/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();

  test('az, en, ru, tr, es, de, it, zh, ja, ko, ar, fa, hi, pt, vi, fr are supported with az as primary', () {
    expect(codes, containsAll(['az', 'en', 'ru', 'tr', 'es', 'de', 'it', 'zh', 'ja', 'ko', 'ar', 'fa', 'hi', 'pt', 'vi', 'fr']));
    expect(AppLocalizations.primary.languageCode, 'az');
  });

  test('Arabic and Persian have native names and resolve their own tables', () {
    expect(AppLocalizations.nativeName('ar'), 'العربية');
    expect(AppLocalizations.nativeName('fa'), 'فارسی');
    expect(const AppLocalizations(Locale('ar')).tr('nav_home'), 'الرئيسية');
    expect(const AppLocalizations(Locale('fa')).tr('nav_home'), 'خانه');
    expect(AppLocalizations.nativeName('vi'), 'Tiếng Việt');
    expect(const AppLocalizations(Locale('vi')).tr('nav_home'), 'Trang chủ');
    expect(
      const AppLocalizations(Locale('vi')).tr('transfer_success', {'n': 5, 'name': 'Lan'}),
      allOf(contains('5'), contains('Lan')),
    );
    expect(AppLocalizations.nativeName('pt'), 'Português');
    expect(const AppLocalizations(Locale('pt')).tr('nav_home'), 'Início');
    expect(
      const AppLocalizations(Locale('pt')).tr('transfer_success', {'n': 5, 'name': 'Ana'}),
      allOf(contains('5'), contains('Ana')),
    );
    expect(AppLocalizations.nativeName('hi'), 'हिन्दी');
    expect(const AppLocalizations(Locale('hi')).tr('nav_home'), 'होम');
    expect(
      const AppLocalizations(Locale('hi')).tr('transfer_success', {'n': 5, 'name': 'Ali'}),
      allOf(contains('5'), contains('Ali')),
    );
    expect(
      const AppLocalizations(Locale('ar')).tr('transfer_success', {'n': 5, 'name': 'Ali'}),
      contains('5'),
    );
  });

  test('every language has a flag and an English name', () {
    for (final c in codes) {
      expect(AppLocalizations.flag(c), isNot('🌐'), reason: c);
      expect(AppLocalizations.englishName(c), isNot(c), reason: c);
    }
    expect(AppLocalizations.flag('az'), '🇦🇿');
    expect(AppLocalizations.flag('xx'), '🌐');
  });

  test('language search matches native name, English name and code', () {
    expect(AppLocalizations.matchesQuery('tr', ''), isTrue);
    expect(AppLocalizations.matchesQuery('tr', 'turkce'), isTrue);
    expect(AppLocalizations.matchesQuery('tr', 'Türk'), isTrue);
    expect(AppLocalizations.matchesQuery('es', 'espanol'), isTrue);
    expect(AppLocalizations.matchesQuery('az', 'azerbaycan'), isTrue);
    expect(AppLocalizations.matchesQuery('pt', 'portugues'), isTrue);
    expect(AppLocalizations.matchesQuery('fa', 'farsi'), isTrue);
    expect(AppLocalizations.matchesQuery('ar', 'arab'), isTrue);
    expect(AppLocalizations.matchesQuery('ar', 'ع'), isTrue);
    expect(AppLocalizations.matchesQuery('ja', 'jap'), isTrue);
    expect(AppLocalizations.matchesQuery('de', 'xyz'), isFalse);
    final hits = codes.where((c) => AppLocalizations.matchesQuery(c, 'ar'));
    expect(hits, contains('ar'));
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
