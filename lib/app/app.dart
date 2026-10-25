import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return MaterialApp.router(
      title: 'EcoPoint',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
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
