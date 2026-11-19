/// EcoFriend smart-message system — pure Dart (no Flutter / Firebase), shared by
/// the app and the Android widget (the widget receives the pre-translated
/// pools written by `widget_sync.dart` and only rotates through them).
///
/// Messages only *describe* real, backend-confirmed state (goal %, streak,
/// last recycle…). Nothing here creates or changes EP.
library;

/// The four daily scenes. Same boundaries as the widget art:
/// morning 05:00–09:59, day 10:00–15:59, evening 16:00–19:59,
/// night 20:00–04:59.
enum EcoScene {
  morning,
  day,
  evening,
  night;

  static EcoScene at(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 10) return EcoScene.morning;
    if (h >= 10 && h < 16) return EcoScene.day;
    if (h >= 16 && h < 20) return EcoScene.evening;
    return EcoScene.night;
  }

  /// First hour of the scene that follows this one.
  int get endHour => switch (this) {
        EcoScene.morning => 10,
        EcoScene.day => 16,
        EcoScene.evening => 20,
        EcoScene.night => 5,
      };
}

/// What the user's real data says right now.
class EcoMsgContext {
  const EcoMsgContext({
    required this.now,
    this.goalPct = -1,
    this.streak = 0,
    this.activeToday = false,
    this.lastScan,
    this.levelFraction = 0,
    this.isMaxLevel = false,
    this.hasEarned = true,
    this.inactiveDays = 0,
  });

  final DateTime now;

  /// Daily goal 0..100, or -1 when there are no missions (unknown).
  final int goalPct;
  final int streak;
  final bool activeToday;

  /// Time of the last confirmed recycling credit, if known.
  final DateTime? lastScan;

  /// 0..1 progress toward the next level.
  final double levelFraction;
  final bool isMaxLevel;

  /// False for a brand-new account (no EP earned yet).
  final bool hasEarned;
  final int inactiveDays;
}

/// A message key + the values for its `{placeholders}`.
class EcoMsg {
  const EcoMsg(this.key, [this.args = const {}]);
  final String key;
  final Map<String, Object?> args;

  @override
  bool operator ==(Object o) => o is EcoMsg && o.key == key;
  @override
  int get hashCode => key.hashCode;
}

abstract final class EcoFriendMessages {
  static const _scene = {
    EcoScene.morning: ['efm_morning_1', 'efm_morning_2', 'efm_morning_3'],
    EcoScene.day: ['efm_day_1', 'efm_day_2', 'efm_day_3'],
    EcoScene.evening: ['efm_evening_1', 'efm_evening_2', 'efm_evening_3'],
    EcoScene.night: ['efm_night_1', 'efm_night_2', 'efm_night_3'],
  };

  /// Scene-only messages (no user state) — also the widget's fallback when
  /// its data is stale (e.g. yesterday's goal).
  static List<EcoMsg> basePool(EcoScene s) =>
      [for (final k in _scene[s]!) EcoMsg(k)];

  /// Streak-at-risk pool (widget shows it natively when the user has not
  /// opened the app today). Not shown at night after 22:00 to avoid pressure.
  static List<EcoMsg> riskPool(int streak) => [
        const EcoMsg('efm_streak_risk'),
        EcoMsg('efm_streak_keep', {'n': streak}),
      ];

  /// Ordered candidates for [scene] given the user's state. The list is a
  /// *mix* (state messages interleaved with the scene greeting) so rotation
  /// never feels repetitive; urgent states come first.
  static List<EcoMsg> pool(EcoScene scene, EcoMsgContext c) {
    final base = basePool(scene);
    final out = <EcoMsg>[];
    final urgent = <EcoMsg>[];
    final soft = <EcoMsg>[];

    // Gentle comeback (3–6 days away). 7+ days = the `sad` mood's own line.
    if (c.inactiveDays >= 3 && c.inactiveDays < 7) {
      urgent.add(const EcoMsg('efm_comeback'));
    }
    // Streak at risk: has a streak, not opened today, afternoon/evening only.
    if (c.streak > 0 && !c.activeToday && c.now.hour >= 16 && c.now.hour < 22) {
      urgent.addAll(riskPool(c.streak));
    }
    if (c.goalPct >= 100) {
      soft.addAll(const [EcoMsg('efm_goal_done_1'), EcoMsg('efm_goal_done_2')]);
    } else if (c.goalPct >= 80) {
      urgent.add(const EcoMsg('efm_goal_close'));
    } else if (c.goalPct >= 50) {
      soft.add(const EcoMsg('efm_goal_half'));
    } else if (c.goalPct == 0 && scene != EcoScene.night) {
      soft.add(const EcoMsg('efm_goal_start'));
    }
    final ls = c.lastScan;
    if (ls != null && c.now.difference(ls) < const Duration(hours: 6)) {
      soft.add(const EcoMsg('efm_recent_scan'));
    }
    if (!c.isMaxLevel && c.levelFraction >= 0.8 && c.levelFraction < 1) {
      soft.add(const EcoMsg('efm_level_close'));
    }
    if (!c.hasEarned && scene != EcoScene.night) {
      urgent.add(const EcoMsg('efm_new_user'));
    }
    if (c.streak >= 3 && c.activeToday && scene != EcoScene.night) {
      soft.add(EcoMsg('efm_streak_keep', {'n': c.streak}));
    }

    out.addAll(urgent);
    // interleave soft state messages with scene greetings
    var bi = 0;
    for (final s in soft) {
      if (bi < base.length) out.add(base[bi++]);
      out.add(s);
    }
    while (bi < base.length) {
      out.add(base[bi++]);
    }
    // de-duplicate, keep order
    final seen = <String>{};
    return [
      for (final m in out)
        if (seen.add(m.key)) m
    ];
  }

  /// Deterministic rotation: changes every 3 hours and every day, and never
  /// returns [lastKey] twice in a row when there is another choice.
  static int slot(DateTime t) {
    final doy = t.difference(DateTime(t.year)).inDays;
    return doy * 8 + t.hour ~/ 3;
  }

  static EcoMsg pick(List<EcoMsg> pool, DateTime now, {String? lastKey}) {
    if (pool.isEmpty) return const EcoMsg('ef_normal');
    var i = slot(now) % pool.length;
    if (pool.length > 1 && pool[i].key == lastKey) i = (i + 1) % pool.length;
    return pool[i];
  }
}
