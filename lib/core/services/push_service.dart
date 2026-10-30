import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../features/wallet/data/wallet_providers.dart';
import 'backend_service.dart';
import 'preferences.dart';
import 'firebase_bootstrap.dart';
import 'firebase_providers.dart';

/// Lets push handling show an in-app banner while the app is open.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Topic that receives admin broadcasts. Mirrors `NEWS_TOPIC` on the server.
const String kNewsTopic = 'news';

/// Firebase Cloud Messaging glue. The server sends the pushes; this class only
/// (1) asks for permission, (2) tells the server which device to push to,
/// (3) subscribes to the news topic and (4) reacts to incoming messages.
class PushService {
  PushService(this._backend, {FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final BackendService _backend;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _refreshSub;
  String _lang = 'az';

  static bool get isSupported =>
      !kIsWeb && !kUseEmulator && (Platform.isAndroid || Platform.isIOS);

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Asks for permission (Android 13+ / iOS) and registers this device.
  /// Returns false if the user declined notifications.
  ///
  /// With [ask] false the system prompt is never shown: the device is only
  /// registered if notifications are already allowed (the friendly primer
  /// screen asks first, then calls this with `ask: true`).
  Future<bool> registerDevice(String lang, {bool ask = true}) async {
    _lang = lang;
    final settings = ask
        ? await _messaging.requestPermission()
        : await _messaging.getNotificationSettings();
    final status = settings.authorizationStatus;
    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      return false;
    }
    final token = await _messaging.getToken();
    if (token != null) await _send(token);
    _refreshSub ??= _messaging.onTokenRefresh.listen(
      (t) => unawaited(_send(t)),
      onError: (_) {},
    );
    return true;
  }

  /// True when the system permission is still undecided or not granted.
  Future<bool> needsPermission() async {
    try {
      final s = (await _messaging.getNotificationSettings()).authorizationStatus;
      return s == AuthorizationStatus.notDetermined;
    } catch (_) {
      return false;
    }
  }

  Future<void> _send(String token) async {
    try {
      await _backend.call('registerPushToken', {
        'token': token,
        'platform': _platform,
        // The server writes reminders in the user's app language.
        'lang': _lang,
      });
    } catch (_) {
      // Retried on the next app start; push is optional.
    }
  }

  Future<void> setNewsSubscribed(bool on) async {
    try {
      if (on) {
        await _messaging.subscribeToTopic(kNewsTopic);
      } else {
        await _messaging.unsubscribeFromTopic(kNewsTopic);
      }
    } catch (_) {}
  }

  /// Call BEFORE signing out so a shared phone stops receiving this user's
  /// pushes (the server call needs the still-valid sign-in).
  Future<void> unregister() async {
    if (!isSupported) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _backend.call('unregisterPushToken', {'token': token});
      }
      await _messaging.unsubscribeFromTopic(kNewsTopic);
    } catch (_) {}
  }

  void dispose() => _refreshSub?.cancel();
}

final pushServiceProvider = Provider<PushService>((ref) {
  final svc = PushService(ref.watch(backendServiceProvider));
  ref.onDispose(svc.dispose);
  return svc;
});

bool _pushReady(Ref ref) {
  final boot = ref.watch(bootProvider);
  return PushService.isSupported && boot.isReady;
}

/// Registers the device once per signed-in user.
final pushRegistrationProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(uidProvider);
  if (uid == null || !_pushReady(ref)) return;
  // Re-registers when the app language changes so reminders follow it.
  final lang = ref.watch(localeProvider).languageCode;
  try {
    await ref.read(pushServiceProvider).registerDevice(lang, ask: false);
  } catch (_) {}
});

/// Keeps the news-topic subscription in line with the user's preference.
final pushTopicProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(uidProvider);
  if (uid == null || !_pushReady(ref)) return;
  final news = ref.watch(
    profileProvider.select((p) => p.valueOrNull?.notifyNews ?? true),
  );
  await ref.read(pushServiceProvider).setNewsSubscribed(news);
});

/// Screens a notification may open. Anything else falls back to the inbox,
/// so a crafted message can never navigate somewhere unexpected.
const Set<String> kPushRoutes = {
  '/home', '/rewards', '/bins', '/profile', '/challenges', '/scan',
  '/leaderboard', '/notifications', '/referral', '/stats',
};
const Set<String> _tabRoutes = {'/home', '/rewards', '/bins', '/profile'};

void openPushRoute(GoRouter router, Object? raw) {
  final route = raw is String && kPushRoutes.contains(raw) ? raw : '/notifications';
  if (_tabRoutes.contains(route)) {
    router.go(route);
    return;
  }
  router.go('/home');
  router.push(route);
}

/// Foreground banner + "open the app from a notification" routing.
final pushListenersProvider = Provider<void>((ref) {
  if (!_pushReady(ref)) return;
  final subs = <StreamSubscription<RemoteMessage>>[];

  subs.add(FirebaseMessaging.onMessage.listen((m) {
    final n = m.notification;
    if (n == null) return;
    final text = [n.title, n.body].whereType<String>().join(' — ');
    rootMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => openPushRoute(ref.read(routerProvider), m.data['route']),
        ),
      ));
  }));

  void open(RemoteMessage m) =>
      openPushRoute(ref.read(routerProvider), m.data['route']);
  subs.add(FirebaseMessaging.onMessageOpenedApp.listen(open));
  FirebaseMessaging.instance.getInitialMessage().then((m) {
    if (m != null) open(m);
  });

  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });
});
