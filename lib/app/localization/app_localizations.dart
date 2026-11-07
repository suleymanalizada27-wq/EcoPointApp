import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings_ar.dart';
import 'strings_az.dart';
import 'strings_de.dart';
import 'strings_en.dart';
import 'strings_es.dart';
import 'strings_fr.dart';
import 'strings_fa.dart';
import 'strings_hi.dart';
import 'strings_it.dart';
import 'strings_ja.dart';
import 'strings_ko.dart';
import 'strings_pt.dart';
import 'strings_ru.dart';
import 'strings_tr.dart';
import 'strings_vi.dart';
import 'strings_zh.dart';

/// Lightweight, code-generation-free localisation.
///
/// * Azerbaijani is the primary and fallback language.
/// * Arabic (`ar`) and Persian (`fa`) are right-to-left; Flutter flips the
///   layout automatically from the locale.
/// * All languages share one key set (see `test/localization_test.dart`).
/// * Placeholders use `{name}` syntax: `context.tr('transfer_success',
///   {'n': 50, 'name': 'Aysel'})`.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const Locale primary = Locale('az');

  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru'),
    Locale('tr'),
    Locale('es'),
    Locale('de'),
    Locale('it'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('ar'),
    Locale('fa'),
    Locale('hi'),
    Locale('pt'),
    Locale('vi'),
    Locale('fr'),
  ];

  static const Map<String, Map<String, String>> _tables = {
    'az': stringsAz,
    'en': stringsEn,
    'ru': stringsRu,
    'tr': stringsTr,
    'es': stringsEs,
    'de': stringsDe,
    'it': stringsIt,
    'zh': stringsZh,
    'ja': stringsJa,
    'ko': stringsKo,
    'ar': stringsAr,
    'fa': stringsFa,
    'hi': stringsHi,
    'pt': stringsPt,
    'vi': stringsVi,
    'fr': stringsFr,
  };

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(primary);
  }

  /// Native display name for the language picker.
  static String nativeName(String code) {
    switch (code) {
      case 'az':
        return 'Azərbaycanca';
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'tr':
        return 'Türkçe';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'ar':
        return 'العربية';
      case 'fa':
        return 'فارسی';
      case 'hi':
        return 'हिन्दी';
      case 'pt':
        return 'Português';
      case 'vi':
        return 'Tiếng Việt';
      case 'fr':
        return 'Français';
      default:
        return code;
    }
  }

  /// Flag emoji shown next to the language in the picker.
  static String flag(String code) {
    switch (code) {
      case 'az':
        return '🇦🇿';
      case 'en':
        return '🇬🇧';
      case 'ru':
        return '🇷🇺';
      case 'tr':
        return '🇹🇷';
      case 'es':
        return '🇪🇸';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      case 'zh':
        return '🇨🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'ar':
        return '🇸🇦';
      case 'fa':
        return '🇮🇷';
      case 'hi':
        return '🇮🇳';
      case 'pt':
        return '🇧🇷';
      case 'vi':
        return '🇻🇳';
      case 'fr':
        return '🇫🇷';
      default:
        return '🌐';
    }
  }

  /// English name of the language, so people can search in English too.
  static String englishName(String code) {
    switch (code) {
      case 'az':
        return 'Azerbaijani';
      case 'en':
        return 'English';
      case 'ru':
        return 'Russian';
      case 'tr':
        return 'Turkish';
      case 'es':
        return 'Spanish';
      case 'de':
        return 'German';
      case 'it':
        return 'Italian';
      case 'zh':
        return 'Chinese';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'ar':
        return 'Arabic';
      case 'fa':
        return 'Persian Farsi';
      case 'hi':
        return 'Hindi';
      case 'pt':
        return 'Portuguese';
      case 'vi':
        return 'Vietnamese';
      case 'fr':
        return 'French';
      default:
        return code;
    }
  }

  static const Map<String, String> _fold1 = {
    'ı': 'i',
    'ə': 'e',
    'ö': 'o',
    'ü': 'u',
    'ç': 'c',
    'ş': 's',
    'ğ': 'g',
    'đ': 'd',
    'ñ': 'n',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
  };

  /// Lower-cases and strips common Latin diacritics so that `turkce`
  /// finds `Türkçe` and `espanol` finds `Español`.
  static String _fold(String input) {
    final lower = input.toLowerCase().replaceAll('\u0307', '').trim();
    final out = StringBuffer();
    for (final ch in lower.split('')) {
      out.write(_fold1[ch] ?? ch);
    }
    return out.toString();
  }

  /// Whether [code] matches a picker search [query]: by native name,
  /// English name or language code. An empty query matches everything.
  static bool matchesQuery(String code, String query) {
    final q = _fold(query);
    if (q.isEmpty) return true;
    return _fold(nativeName(code)).contains(q) ||
        _fold(englishName(code)).contains(q) ||
        code.toLowerCase().startsWith(q);
  }

  /// Looks up [key]; falls back to Azerbaijani, then to the key itself.
  String tr(String key, [Map<String, Object?> args = const {}]) {
    final table = _tables[locale.languageCode] ?? stringsAz;
    var value = table[key] ?? stringsAz[key] ?? key;
    if (args.isNotEmpty) {
      args.forEach((name, v) {
        value = value.replaceAll('{$name}', '${v ?? ''}');
      });
    }
    return value;
  }

  @visibleForTesting
  static Map<String, String> tableFor(String code) =>
      _tables[code] ?? stringsAz;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Shorthand for `AppLocalizations.of(context).tr(...)`.
  String tr(String key, [Map<String, Object?> args = const {}]) =>
      AppLocalizations.of(this).tr(key, args);
}
