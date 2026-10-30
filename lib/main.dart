import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/backend_service.dart';
import 'core/services/error_reporter.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/firebase_providers.dart';
import 'core/services/preferences.dart';
import 'core/services/session_restore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  final boot = await FirebaseBootstrap.init();

  // Wake a sleeping free-tier backend while the UI starts.
  ErrorReporter? reporter;
  var restored = false;
  if (boot.isReady) {
    final backend = BackendService(FirebaseAuth.instance);
    unawaited(backend.warmUp());
    reporter = ErrorReporter(backend);
    await reporter.install();
    FirebaseAuth.instance.userChanges().listen((u) => reporter?.setUser(u?.uid));
    // Quietly sign Google users back in if the phone lost the session.
    restored = await SessionRestore.restoreIfLost();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        bootProvider.overrideWithValue(boot),
      ],
      child: const EcoPointApp(),
    ),
  );
  if (restored) {
    // Diagnostic for the admin error log: how often the phone loses sessions.
    unawaited(reporter?.report(
        'INFO session restored via Google silent sign-in (Firebase session was lost)',
        null));
  }
}
