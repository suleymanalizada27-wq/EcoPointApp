/// EcoFriend mascot — pure-Dart state engine (no Flutter / Firebase imports,
/// so it is unit-testable and shared by the app and the home-screen widget).
///
/// EcoFriend never creates, changes or confirms EP. It only *reacts* to events
/// that the existing backend has already confirmed.
library;

enum EcoFriendMood {
  normal,
  breathing,
  sad,
  excited,
  cheering,
  proud,
  thinking;

  String get animatedAsset => 'assets/ecofriend/$name.webp';
  String get stillAsset => 'assets/ecofriend/still/$name.png';

  /// Higher priority interrupts lower; resting moods are never "events".
  int get priority => switch (this) {
        normal || breathing => 0,
        sad => 5,
        thinking => 20,
        excited => 30,
        proud => 40,
        cheering => 50,
      };

  /// How long a temporary mood plays before returning to the resting mood.
  /// `null` = held until released (thinking) or resting.
  Duration? get hold => switch (this) {
        normal || breathing => null,
        thinking => null,
        sad => const Duration(seconds: 9),
        excited => const Duration(milliseconds: 5200),
        cheering => const Duration(milliseconds: 3800),
        proud => const Duration(milliseconds: 3800),
      };

  /// Message key (see `ef_*` in the string tables).
  String get messageKey => 'ef_$name';

  bool get isEvent => priority > 0;
}

/// Longest time "thinking" may be held (safety net if a release is missed).
const Duration kThinkingMax = Duration(seconds: 30);

/// The same mood is not re-fired by a *different* event key within this window.
const Duration kMoodCooldown = Duration(seconds: 20);

class _Active {
  _Active(this.mood, this.until, this.token);
  final EcoFriendMood mood;
  final DateTime until;
  final String? token;
}

class EcoFriendEngine {
  EcoFriendEngine({this.resting = EcoFriendMood.normal});

  /// Resting mood when nothing is happening (normal or breathing).
  EcoFriendMood resting;

  _Active? _active;
  final Set<String> _seenKeys = <String>{};
  final Map<EcoFriendMood, DateTime> _lastAt = {};

  EcoFriendMood current(DateTime now) {
    _expire(now);
    return _active?.mood ?? resting;
  }

  /// When the current temporary mood ends (null if resting).
  DateTime? activeUntil(DateTime now) {
    _expire(now);
    return _active?.until;
  }

  void _expire(DateTime now) {
    final a = _active;
    if (a != null && !now.isBefore(a.until)) _active = null;
  }

  /// Tries to start [mood]. Returns true if it was accepted.
  ///
  /// * the same [eventKey] never plays twice;
  /// * a mood already active with >= priority is not interrupted
  ///   (so cheering is never overlapped by ordinary events);
  /// * the same mood cannot be re-fired by a different key within
  ///   [kMoodCooldown] (e.g. scan result + balance stream = one reaction).
  bool trigger(
    EcoFriendMood mood, {
    required DateTime now,
    String? eventKey,
    String? token,
  }) {
    if (!mood.isEvent) {
      resting = mood;
      return true;
    }
    _expire(now);
    if (eventKey != null && _seenKeys.contains(eventKey)) return false;
    final a = _active;
    if (a != null && a.mood.priority >= mood.priority) return false;
    final last = _lastAt[mood];
    if (token == null && last != null && now.difference(last) < kMoodCooldown) {
      return false;
    }
    final hold = token != null ? kThinkingMax : (mood.hold ?? kThinkingMax);
    _active = _Active(mood, now.add(hold), token);
    if (eventKey != null) _seenKeys.add(eventKey);
    if (token == null) _lastAt[mood] = now;
    return true;
  }

  /// Releases a held mood (thinking) started with [token].
  bool release(String token) {
    final a = _active;
    if (a != null && a.token == token) {
      _active = null;
      return true;
    }
    return false;
  }
}

/// Mood shown on the Android home-screen widget. Pure function so Dart and
/// Kotlin (see EpWidgetProvider.kt) agree: a recent *backend-confirmed* event
/// wins, then long inactivity (returning users only) → sad, else normal.
EcoFriendMood widgetMoodAt({
  required DateTime now,
  EcoFriendMood? eventMood,
  DateTime? eventUntil,
  DateTime? lastActive,
  Duration inactiveAfter = const Duration(days: 7),
}) {
  if (eventMood != null &&
      (eventMood == EcoFriendMood.excited ||
          eventMood == EcoFriendMood.cheering ||
          eventMood == EcoFriendMood.proud) &&
      eventUntil != null &&
      now.isBefore(eventUntil)) {
    return eventMood;
  }
  if (lastActive != null && now.difference(lastActive) >= inactiveAfter) {
    return EcoFriendMood.sad;
  }
  return EcoFriendMood.normal;
}

/// How long a confirmed event stays on the home-screen widget.
Duration widgetHoldFor(EcoFriendMood m) => switch (m) {
      EcoFriendMood.excited => const Duration(hours: 3),
      EcoFriendMood.cheering => const Duration(hours: 8),
      EcoFriendMood.proud => const Duration(hours: 12),
      _ => Duration.zero,
    };
