import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../challenges/data/gamification_repository.dart';
import '../../wallet/data/wallet_providers.dart';
import '../domain/ecofriend_messages.dart';

/// The user's *real* state as the message engine sees it (read-only: derived
/// from the same providers the rest of the app uses; nothing is invented).
///
/// `now` is the moment the context was last rebuilt; callers that need the
/// current time (scene, rotation slot) pass their own `DateTime.now()` to
/// [EcoFriendMessages.pool] / [EcoFriendMessages.pick].
final ecoMsgContextProvider = Provider<EcoMsgContext>((ref) {
  final missions = ref.watch(missionsProvider);
  final total = missions.length;
  final done = missions.where((m) => m.complete).length;
  final streak = ref.watch(streakProvider).valueOrNull?.count ?? 0;
  final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final level = ref.watch(levelProgressProvider);
  final stats = ref.watch(statsProvider).valueOrNull;

  DateTime? lastScan;
  for (final t in txs) {
    if (!t.isEarning) continue;
    if (lastScan == null || t.time.isAfter(lastScan)) lastScan = t.time;
  }

  return EcoMsgContext(
    now: DateTime.now(),
    goalPct: total == 0 ? -1 : (done * 100 ~/ total).clamp(0, 100),
    streak: streak,
    // The person is in the app right now.
    activeToday: true,
    lastScan: lastScan,
    levelFraction: level.fraction,
    isMaxLevel: level.isMax,
    // Do not flash the "first scan" hint while stats are still loading.
    hasEarned: stats == null ? true : (stats.earned > 0 || stats.scans > 0),
  );
});
