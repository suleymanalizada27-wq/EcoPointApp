import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../features/wallet/data/wallet_providers.dart';
import 'backend_service.dart';
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

  static bool get isSupported =>
      !kIsWeb && !kUseEmulator && (Platform.isAndroid || Platform.isIOS);

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Asks for permission (Android 13+ / iOS) and registers this device.
  /// Returns false if the user declined notifications.
  Future<bool> registerDevice() async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
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

  Future<void> _send(String token) async {
    try {
      await _backend.call('registerPushToken', {
        'token': token,
        'platform': _platform,
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
  try {
    await ref.read(pushServiceProvider).registerDevice();
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
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }));

  void open() => ref.read(routerProvider).go('/notifications');
  subs.add(FirebaseMessaging.onMessageOpenedApp.listen((_) => open()));
  FirebaseMessaging.instance.getInitialMessage().then((m) {
    if (m != null) open();
  });

  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });
});
