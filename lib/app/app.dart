import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/preferences.dart';
import '../core/services/push_service.dart';
import 'localization/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class EcoPointApp extends ConsumerWidget {
  const EcoPointApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);
    final useDynamic = ref.watch(dynamicColorProvider);

    return DynamicColorBuilder(
      builder: (lightDyn, darkDyn) => _app(
        router,
        locale,
        mode,
        useDynamic ? lightDyn?.primary : null,
        useDynamic ? darkDyn?.primary : null,
      ),
    );
  }

  Widget _app(
    GoRouter router,
    Locale locale,
    ThemeMode mode,
    Color? lightAccent,
    Color? darkAccent,
  ) {
    return MaterialApp.router(
      title: 'EcoPoint',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: router,
      theme: AppTheme.localized(
          lightAccent == null
              ? AppTheme.light
              : AppTheme.withAccent(lightAccent, Brightness.light),
          locale),
      darkTheme: AppTheme.localized(
          darkAccent == null
              ? AppTheme.dark
              : AppTheme.withAccent(darkAccent, Brightness.dark),
          locale),
      themeMode: mode,
      // Respect the system font size (up to 1.6x) without breaking layouts.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 1.6),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
