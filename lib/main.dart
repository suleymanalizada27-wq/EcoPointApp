import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/backend_service.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/firebase_providers.dart';
import 'core/services/preferences.dart';

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
  if (boot.isReady) unawaited(BackendService(FirebaseAuth.instance).warmUp());

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        bootProvider.overrideWithValue(boot),
      ],
      child: const EcoPointApp(),
    ),
  );
}
