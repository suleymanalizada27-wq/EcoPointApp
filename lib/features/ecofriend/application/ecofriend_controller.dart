import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_providers.dart';
import '../../../core/services/preferences.dart';
import '../../../core/utils/formatters.dart';
import '../../challenges/data/gamification_repository.dart';
import '../../wallet/data/wallet_providers.dart';
import '../domain/ecofriend_engine.dart';

/// What the home-screen widget needs to know (persisted, time-aware).
@immutable
class EcoFriendWidgetData {
  const EcoFriendWidgetData({
    this.eventMood = '',
    this.eventUntilMs = 0,
    this.lastActiveMs = 0,
  });

  /// `excited` / `cheering` / `proud` or '' (none).
  final String eventMood;
  final int eventUntilMs;
  final int lastActiveMs;

  @override
  bool operator ==(Object other) =>
      other is EcoFriendWidgetData &&
      other.eventMood == eventMood &&
      other.eventUntilMs == eventUntilMs &&
      other.lastActiveMs == lastActiveMs;

  @override
  int get hashCode => Object.hash(eventMood, eventUntilMs, lastActiveMs);
}

@immutable
class EcoFriendSnapshot {
  const EcoFriendSnapshot({
    required this.mood,
    required this.widget,
    this.msgKey,
    this.msgArgs = const {},
  });

  final EcoFriendMood mood;
  final EcoFriendWidgetData widget;

  /// Optional message that belongs to the current event (e.g. streak
  /// milestone). Null = use the mood's default message.
  final String? msgKey;
  final Map<String, Object?> msgArgs;

  /// Localised text of the current event (or of the resting mood).
  String text(String Function(String, [Map<String, Object?>]) tr) =>
      tr(msgKey ?? mood.messageKey, msgArgs);
}

const List<int> _kStreakMilestones = [3, 7, 14, 30, 60, 100, 365];

const _kLastActive = 'ef-last-active';
const _kWidgetMood = 'ef-w-mood';
const _kWidgetUntil = 'ef-w-until';
const _kGoalDay = 'ef-goal-day';
const _kLevelSeen = 'ef-level-seen';

/// Single source of truth for EcoFriend. Dashboard, scanner, state views and
/// the Android widget (via `widget_sync.dart`) all read this.
///
/// EcoFriend only *reacts*: it never writes EP, never calls the backend and
/// only celebrates things the backend already confirmed (RTDB balance stream,
/// server-confirmed QR session, server-side mission/level data).
class EcoFriendController extends Notifier<EcoFriendSnapshot>
    with WidgetsBindingObserver {
  final EcoFriendEngine _engine = EcoFriendEngine();
  Timer? _timer;
  Timer? _settle;
  int? _lastBalance;
  bool _goalSeeded = false;
  bool _goalWasComplete = false;
  int _lastActiveMs = 0;
  String? _msgKey;
  Map<String, Object?> _msgArgs = const {};
  EcoFriendMood? _msgMood;

  @override
  EcoFriendSnapshot build() {
    final prefs = ref.read(sharedPrefsProvider);
    final now = DateTime.now();

    final prevMs = prefs.getInt(_kLastActive);
    _lastActiveMs = now.millisecondsSinceEpoch;
    prefs.setInt(_kLastActive, _lastActiveMs);

    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
      _settle?.cancel();
    });

    // Greeting (normal) first, then the calm breathing loop.
    _settle = Timer(const Duration(seconds: 6), () {
      _engine.resting = EcoFriendMood.breathing;
      _refresh();
    });

    // Returning after a long break (never for brand-new users: no stored
    // timestamp yet). Gentle — a short "welcome back", no guilt message.
    if (prevMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(prevMs)) >=
            const Duration(days: 7)) {
      _engine.trigger(EcoFriendMood.sad,
          now: now, eventKey: 'sad_${Fmt.dayKey(now)}');
      _schedule();
    }

    _listen();
    return _snapshot(now);
  }

  // ---------------------------------------------------------------- events

  void _listen() {
    // Account switch: forget per-user baselines.
    ref.listen<String?>(uidProvider, (_, __) {
      _lastBalance = null;
      _goalSeeded = false;
      _goalWasComplete = false;
    });

    // New EP confirmed by the backend → excited. The first value only seeds.
    ref.listen<AsyncValue<int>>(balanceProvider, (_, next) {
      if (next is! AsyncData<int>) return;
      final n = next.value;
      final p = _lastBalance;
      _lastBalance = n;
      if (p == null || n <= p) return;
      _fire(EcoFriendMood.excited, key: 'bal_$n');
    });

    // Daily goal complete (all daily missions) → cheering, once per day.
    ref.listen(missionsProvider, (_, missions) {
      final loaded = ref.read(transactionsProvider).hasValue &&
          ref.read(streakProvider).hasValue &&
          ref.read(claimedTodayProvider).hasValue;
      if (!loaded || missions.isEmpty) return;
      final complete = missions.every((m) => m.complete);
      if (!_goalSeeded) {
        _goalSeeded = true;
        _goalWasComplete = complete;
        return;
      }
      final was = _goalWasComplete;
      _goalWasComplete = complete;
      if (!complete || was) return;
      final prefs = ref.read(sharedPrefsProvider);
      final day = Fmt.dayKey(DateTime.now());
      if (prefs.getString(_kGoalDay) == day) return;
      if (_fire(EcoFriendMood.cheering, key: 'goal_$day')) {
        prefs.setString(_kGoalDay, day);
      }
    });

    // Streak milestone (server-side check-in streak) → proud with its own line.
    ref.listen(streakProvider, (_, next) {
      if (next is! AsyncData) return;
      final uid = ref.read(uidProvider);
      if (uid == null) return;
      final n = next.value?.count ?? 0;
      final prefs = ref.read(sharedPrefsProvider);
      final key = 'ef-streak-seen-$uid';
      final seen = prefs.getInt(key);
      if (seen == null) {
        prefs.setInt(key, n);
        return;
      }
      if (n <= seen) {
        if (n < seen) prefs.setInt(key, n); // streak was reset
        return;
      }
      prefs.setInt(key, n);
      final hit = _kStreakMilestones.where((m) => m > seen && m <= n);
      if (hit.isEmpty) return;
      _fire(EcoFriendMood.proud,
          key: 'streak_$uid-${hit.last}',
          msgKey: 'ef_streak',
          msgArgs: {'n': hit.last});
    });

    // New level (lifetime earned EP crossed a threshold) → proud.
    ref.listen(statsProvider, (_, next) {
      if (next is! AsyncData) return;
      final uid = ref.read(uidProvider);
      if (uid == null) return;
      final idx = ref.read(levelProgressProvider).current.index;
      final prefs = ref.read(sharedPrefsProvider);
      final key = '$_kLevelSeen-$uid';
      final seen = prefs.getInt(key);
      if (seen == null) {
        prefs.setInt(key, idx);
        return;
      }
      if (idx > seen) {
        prefs.setInt(key, idx);
        _fire(EcoFriendMood.proud, key: 'lvl_$uid-$idx');
      }
    });
  }

  /// Holds "thinking" (QR scanner open, scan in progress, waiting for server).
  void thinking(String token) {
    if (_engine.trigger(EcoFriendMood.thinking,
        now: DateTime.now(), token: token)) {
      _schedule();
      _refresh();
    }
  }

  void endThinking(String token) {
    if (_engine.release(token)) {
      _schedule();
      _refresh();
    }
  }

  /// Server-confirmed QR deposit. [sessionKey] makes it fire only once; the
  /// balance stream firing right after is absorbed by the mood cool-down.
  void scanConfirmed(String sessionKey) =>
      _fire(EcoFriendMood.excited, key: 'scan_$sessionKey');

  // ------------------------------------------------------------ internals

  bool _fire(EcoFriendMood mood,
      {String? key, String? msgKey, Map<String, Object?> msgArgs = const {}}) {
    final now = DateTime.now();
    final ok = _engine.trigger(mood, now: now, eventKey: key);
    if (!ok) return false;
    _msgKey = msgKey;
    _msgArgs = msgArgs;
    _msgMood = mood;
    if (widgetHoldFor(mood) > Duration.zero) {
      final prefs = ref.read(sharedPrefsProvider);
      prefs.setString(_kWidgetMood, mood.name);
      prefs.setInt(
          _kWidgetUntil, now.add(widgetHoldFor(mood)).millisecondsSinceEpoch);
    }
    _touchActive(now);
    _schedule();
    _refresh();
    return true;
  }

  void _touchActive(DateTime now) {
    _lastActiveMs = now.millisecondsSinceEpoch;
    ref.read(sharedPrefsProvider).setInt(_kLastActive, _lastActiveMs);
  }

  /// One timer: wakes up exactly when the current temporary mood ends.
  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final until = _engine.activeUntil(now);
    if (until == null) return;
    _timer = Timer(until.difference(now) + const Duration(milliseconds: 30), () {
      _refresh();
      _schedule();
    });
  }

  void _refresh() {
    final s = _snapshot(DateTime.now());
    if (s.mood != state.mood ||
        s.widget != state.widget ||
        s.msgKey != state.msgKey) {
      state = s;
    }
  }

  EcoFriendSnapshot _snapshot(DateTime now) {
    final prefs = ref.read(sharedPrefsProvider);
    final until = prefs.getInt(_kWidgetUntil) ?? 0;
    var mood = prefs.getString(_kWidgetMood) ?? '';
    if (until <= now.millisecondsSinceEpoch) mood = '';
    final cur = _engine.current(now);
    final hasMsg = _msgKey != null && _msgMood == cur && cur.isEvent;
    return EcoFriendSnapshot(
      mood: cur,
      msgKey: hasMsg ? _msgKey : null,
      msgArgs: hasMsg ? _msgArgs : const {},
      widget: EcoFriendWidgetData(
        eventMood: mood,
        eventUntilMs: mood.isEmpty ? 0 : until,
        lastActiveMs: _lastActiveMs,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _touchActive(DateTime.now());
      _refresh();
    }
  }
}

final ecoFriendProvider =
    NotifierProvider<EcoFriendController, EcoFriendSnapshot>(
        EcoFriendController.new);

/// Just the mood (rebuilds only when it changes).
final ecoFriendMoodProvider = Provider<EcoFriendMood>(
    (ref) => ref.watch(ecoFriendProvider.select((s) => s.mood)));
