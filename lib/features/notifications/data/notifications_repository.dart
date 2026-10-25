import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/services/preferences.dart';
import '../../../core/utils/json_utils.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.personal,
  });
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool personal;
}

/// Merges broadcast (`globalNotifications`) and personal
/// (`users/{uid}/notifications`) feeds, newest first.
class NotificationsRepository {
  NotificationsRepository(this._db);
  final FirebaseDatabase _db;

  Stream<List<AppNotification>> feed(String uid) {
    List<AppNotification> parse(DataSnapshot s, bool personal) {
      final out = <AppNotification>[];
      for (final c in s.children) {
        final m = asMap(c.value);
        final title = asString(m['title'], asString(m['text']));
        final body = asString(m['body'], asString(m['desc']));
        if (title.isEmpty && body.isEmpty) continue;
        out.add(AppNotification(
          id: '${personal ? 'u' : 'g'}_${c.key}',
          title: title,
          body: body,
          time: DateTime.fromMillisecondsSinceEpoch(asInt(m['ts'])),
          personal: personal,
        ));
      }
      return out;
    }

    final global = _db.ref(DbPaths.globalNotifications).limitToLast(30).onValue;
    final mine = _db.ref(DbPaths.userNotifications(uid)).limitToLast(30).onValue;

    // Combine the two latest snapshots without extra dependencies.
    return _combine(
      global.map((e) => parse(e.snapshot, false)),
      mine.map((e) => parse(e.snapshot, true)),
    );
  }

  Stream<List<AppNotification>> _combine(
    Stream<List<AppNotification>> a,
    Stream<List<AppNotification>> b,
  ) async* {
    var la = const <AppNotification>[];
    var lb = const <AppNotification>[];
    final controller = StreamController<List<AppNotification>>();
    void emit() {
      final all = [...la, ...lb]..sort((x, y) => y.time.compareTo(x.time));
      controller.add(all.take(40).toList());
    }

    final sa = a.listen((v) {
      la = v;
      emit();
    }, onError: controller.addError);
    final sb = b.listen((v) {
      lb = v;
      emit();
    }, onError: controller.addError);
    controller.onCancel = () {
      sa.cancel();
      sb.cancel();
    };
    yield* controller.stream;
  }
}

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const <AppNotification>[]);
  return NotificationsRepository(ref.watch(databaseProvider)).feed(uid);
});

const String _seenKey = 'ep-notif-seen';

/// Timestamp (ms) of the newest notification the user has opened.
class NotifSeenController extends Notifier<int> {
  @override
  int build() => ref.read(sharedPrefsProvider).getInt(_seenKey) ?? 0;

  Future<void> markSeen(int ts) async {
    state = ts;
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt(_seenKey, ts);
  }
}

final notifSeenProvider =
    NotifierProvider<NotifSeenController, int>(NotifSeenController.new);

/// True when something newer than the last-seen timestamp exists.
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final seen = ref.watch(notifSeenProvider);
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return list.any((n) => n.time.millisecondsSinceEpoch > seen);
});
