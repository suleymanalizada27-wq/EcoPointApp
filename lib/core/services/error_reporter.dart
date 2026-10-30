import 'dart:io' show Platform;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'backend_service.dart';

/// Sends uncaught Dart errors to the backend (`reportError`, visible in the
/// admin panel) and — in release builds — to Firebase Crashlytics, which also
/// captures native crashes. Best effort: never throws, de-duplicates.
class ErrorReporter {
  ErrorReporter(this._backend);

  final BackendService _backend;
  final Set<int> _seen = <int>{};
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  /// Route currently shown; updated by the router observer if wired.
  String? screen;

  bool _crashlytics = false;

  Future<void> install() async {
    try {
      _crashlytics = !kDebugMode;
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(_crashlytics);
    } catch (_) {
      _crashlytics = false;
    }
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      if (_crashlytics) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        } catch (_) {}
      }
      report(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_crashlytics) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {}
      }
      report(error, stack);
      return true;
    };
  }

  /// Links crash reports to the (pseudonymous) account id; null on sign-out.
  Future<void> setUser(String? uid) async {
    if (!_crashlytics) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
    } catch (_) {}
  }

  Future<void> report(Object error, StackTrace? stack) async {
    try {
      final message = error.toString();
      final key = Object.hash(message, (stack?.toString() ?? '').length);
      if (!_seen.add(key)) return;
      if (_seen.length > 50) _seen.clear();
      final now = DateTime.now();
      if (now.difference(_last).inSeconds < 3) return;
      _last = now;
      await _backend.call('reportError', {
        'message': _cut(message, 400),
        'stack': _cut(stack?.toString() ?? '', 1500),
        'app': AppConstants.appVersion,
        'platform': Platform.operatingSystem,
        'screen': screen ?? '',
      });
    } catch (_) {
      // Reporting must never cause another error.
    }
  }

  static String _cut(String s, int max) => s.length <= max ? s : s.substring(0, max);
}
