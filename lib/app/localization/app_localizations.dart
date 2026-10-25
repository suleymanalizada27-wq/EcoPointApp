import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings_az.dart';
import 'strings_en.dart';
import 'strings_ru.dart';
import 'strings_tr.dart';

/// Lightweight, code-generation-free localisation.
///
/// * Azerbaijani is the primary and fallback language.
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
  ];

  static const Map<String, Map<String, String>> _tables = {
    'az': stringsAz,
    'en': stringsEn,
    'ru': stringsRu,
    'tr': stringsTr,
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
      default:
        return code;
    }
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
