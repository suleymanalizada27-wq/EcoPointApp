import 'package:flutter/material.dart';

import '../../../core/utils/json_utils.dart';
import '../../wallet/domain/wallet_models.dart';

/// Mirrors `users/{uid}/streak` written by the `claimDailyCheckIn` function.
class StreakState {
  const StreakState({
    this.count = 0,
    this.lastDay = '',
    this.history = const [],
  });

  final int count;

  /// Local calendar day key of the last check-in (`yyyy-MM-dd`).
  final String lastDay;

  /// Up to the last 7 check-in day keys.
  final List<String> history;

  static const StreakState empty = StreakState();

  bool checkedInOn(String dayKey) => lastDay == dayKey;

  factory StreakState.fromMap(Map<String, Object?> m) {
    final h = m['history'];
    return StreakState(
      count: asInt(m['count']),
      lastDay: asString(m['lastDay']),
      history: h is List ? h.map((e) => asString(e)).toList() : const [],
    );
  }
}

enum MissionKind { scansToday, streak }

/// A daily mission. Rewards are paid only by the backend (`claimChallenge`),
/// which recomputes progress itself. (The legacy app displayed these missions
/// but never actually paid them out.)
class MissionDef {
  const MissionDef({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.subKey,
    required this.ep,
    required this.kind,
    required this.goal,
  });

  final String id;
  final IconData icon;
  final String titleKey;
  final String subKey;
  final int ep;
  final MissionKind kind;
  final int goal;

  static const List<MissionDef> all = [
    MissionDef(
      id: 'scan3',
      icon: Icons.recycling_rounded,
      titleKey: 'ch_scan3_t',
      subKey: 'ch_scan3_s',
      ep: 30,
      kind: MissionKind.scansToday,
      goal: 3,
    ),
    MissionDef(
      id: 'scan5',
      icon: Icons.eco_rounded,
      titleKey: 'ch_scan5_t',
      subKey: 'ch_scan5_s',
      ep: 50,
      kind: MissionKind.scansToday,
      goal: 5,
    ),
    MissionDef(
      id: 'streak2',
      icon: Icons.local_fire_department_rounded,
      titleKey: 'ch_streak2_t',
      subKey: 'ch_streak2_s',
      ep: 20,
      kind: MissionKind.streak,
      goal: 2,
    ),
  ];
}

class MissionProgress {
  const MissionProgress({
    required this.def,
    required this.progress,
    required this.claimed,
  });

  final MissionDef def;
  final int progress;
  final bool claimed;

  int get shown => progress > def.goal ? def.goal : progress;
  bool get complete => progress >= def.goal;
  bool get claimable => complete && !claimed;
  double get fraction => def.goal == 0 ? 1 : shown / def.goal;

  static List<MissionProgress> compute({
    required int scansToday,
    required int streak,
    required Set<String> claimedToday,
  }) {
    return MissionDef.all.map((d) {
      final p = d.kind == MissionKind.scansToday ? scansToday : streak;
      return MissionProgress(
        def: d,
        progress: p,
        claimed: claimedToday.contains(d.id),
      );
    }).toList();
  }
}

class AchievementDef {
  const AchievementDef(this.id, this.icon, this.titleKey, this.descKey, this.test);

  final String id;
  final IconData icon;
  final String titleKey;
  final String descKey;
  final bool Function(WalletStats stats, int streak) test;

  static final List<AchievementDef> all = [
    AchievementDef('first_scan', Icons.eco_rounded, 'ach_first_scan_t',
        'ach_first_scan_d', (s, _) => s.scans >= 1),
    AchievementDef('scan10', Icons.recycling_rounded, 'ach_scan10_t',
        'ach_scan10_d', (s, _) => s.scans >= 10),
    AchievementDef('scan50', Icons.local_fire_department_rounded,
        'ach_scan50_t', 'ach_scan50_d', (s, _) => s.scans >= 50),
    AchievementDef('earned500', Icons.savings_rounded, 'ach_earned500_t',
        'ach_earned500_d', (s, _) => s.earned >= 500),
    AchievementDef('earned5000', Icons.rocket_launch_rounded,
        'ach_earned5000_t', 'ach_earned5000_d', (s, _) => s.earned >= 5000),
    AchievementDef('sent1', Icons.send_rounded, 'ach_sent1_t', 'ach_sent1_d',
        (s, _) => s.sent >= 1),
    AchievementDef('streak7', Icons.whatshot_rounded, 'ach_streak7_t',
        'ach_streak7_d', (_, st) => st >= 7),
  ];

  /// Achievements are *derived* from server-maintained stats, so they can't be
  /// forged client-side (the legacy app kept them in localStorage).
  static Set<String> unlocked(WalletStats stats, int streak) =>
      {for (final a in all) if (a.test(stats, streak)) a.id};
}
