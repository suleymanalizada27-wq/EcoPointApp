import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/localization/app_localizations.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider not overridden'),
);

abstract final class PrefKeys {
  // Same keys as the web app's localStorage, so behaviour carries over.
  static const String language = 'ep-lang';
  static const String theme = 'ep-theme';
  static const String onboarded = 'ep-onboarded';
  static const String notifAsks = 'ep-notif-asks';
}

/// App language. Azerbaijani is the default.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final code = ref.read(sharedPrefsProvider).getString(PrefKeys.language);
    final match = AppLocalizations.supportedLocales
        .where((l) => l.languageCode == code)
        .toList();
    return match.isEmpty ? AppLocalizations.primary : match.first;
  }

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    await ref.read(sharedPrefsProvider).setString(PrefKeys.language, code);
  }
}

final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Light / dark / system. Defaults to dark (the web app's identity).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final v = ref.read(sharedPrefsProvider).getString(PrefKeys.theme);
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(PrefKeys.theme, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Whether the onboarding carousel has been completed.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPrefsProvider).getBool(PrefKeys.onboarded) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(PrefKeys.onboarded, true);
  }
}

final onboardedProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
