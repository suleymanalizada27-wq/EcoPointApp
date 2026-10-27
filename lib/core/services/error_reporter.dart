import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'backend_service.dart';

/// Sends uncaught Dart errors to the backend (`reportError`) so the admin
/// can see them. Best effort: never throws, de-duplicates, and only reports
/// while a user is signed in. Native (Java/C++) crashes are NOT covered.
class ErrorReporter {
  ErrorReporter(this._backend);

  final BackendService _backend;
  final Set<int> _seen = <int>{};
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  /// Route currently shown; updated by the router observer if wired.
  String? screen;

  void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      report(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      return true;
    };
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
