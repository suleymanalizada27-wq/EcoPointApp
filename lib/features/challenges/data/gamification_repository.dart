import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json_utils.dart';
import '../../wallet/data/wallet_providers.dart';
import '../../wallet/domain/activity_aggregator.dart';
import '../domain/gamification.dart';

class CheckInResult {
  const CheckInResult({
    required this.streak,
    required this.bonus,
    required this.alreadyDone,
  });
  final int streak;
  final int bonus;
  final bool alreadyDone;
}

class GamificationRepository {
  GamificationRepository(this._db, this._backend);

  final FirebaseDatabase _db;
  final BackendService _backend;

  Stream<StreakState> streak(String uid) => _db
      .ref(DbPaths.streak(uid))
      .onValue
      .map((e) => StreakState.fromMap(asMap(e.snapshot.value)));

  /// Mission ids already claimed *today* (key format `<id>_<yyyy-MM-dd>`).
  Stream<Set<String>> claimedToday(String uid) {
    final suffix = '_${Fmt.dayKey(DateTime.now())}';
    return _db.ref(DbPaths.claims(uid)).limitToLast(60).onValue.map((e) {
      final out = <String>{};
      for (final c in e.snapshot.children) {
        final k = c.key ?? '';
        if (k.endsWith(suffix)) out.add(k.substring(0, k.length - suffix.length));
      }
      return out;
    });
  }

  /// Baku (UTC+4) calendar month key, same as the server's.
  static String monthKey() {
    final d = DateTime.now().toUtc().add(const Duration(hours: 4));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  Stream<int> scansThisMonth(String uid) => _db
      .ref('users/$uid/monthly/${monthKey()}/scans')
      .onValue
      .map((e) => asInt(e.snapshot.value));

  Stream<Set<String>> claimedThisMonth(String uid) {
    final suffix = '_${monthKey()}';
    return _db.ref(DbPaths.claims(uid)).limitToLast(80).onValue.map((e) {
      final out = <String>{};
      for (final c in e.snapshot.children) {
        final k = c.key ?? '';
        if (k.startsWith('m_') && k.endsWith(suffix)) {
          out.add(k.substring(0, k.length - suffix.length));
        }
      }
      return out;
    });
  }

  Future<CheckInResult> checkIn() async {
    final res = await _backend.call('claimDailyCheckIn', {
      'day': Fmt.dayKey(DateTime.now()),
    });
    return CheckInResult(
      streak: asInt(res['streak']),
      bonus: asInt(res['bonus']),
      alreadyDone: asBool(res['alreadyDone']),
    );
  }

  Future<int> claimMission(String id) async {
    if (id.startsWith('m_')) {
      final r = await _backend.call('claimMonthly', {'challengeId': id});
      return asInt(r['ep']);
    }
    final res = await _backend.call('claimChallenge', {
      'challengeId': id,
      'day': Fmt.dayKey(DateTime.now()),
    });
    return asInt(res['ep']);
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(
    ref.watch(databaseProvider),
    ref.watch(backendServiceProvider),
  ),
);

final streakProvider = StreamProvider<StreakState>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(StreakState.empty);
  return ref.watch(gamificationRepositoryProvider).streak(uid);
});

final claimedTodayProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const <String>{});
  return ref.watch(gamificationRepositoryProvider).claimedToday(uid);
});

/// Missions with live progress (scans today come from the transaction feed).
final missionsProvider = Provider<List<MissionProgress>>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final streak = ref.watch(streakProvider).valueOrNull ?? StreakState.empty;
  final claimed = ref.watch(claimedTodayProvider).valueOrNull ?? const {};
  final scansToday = ActivityAggregator.scansOnDay(txs, DateTime.now());
  // A streak only counts if it's still alive (checked in today or yesterday).
  final today = Fmt.dayKey(DateTime.now());
  final yesterday = Fmt.dayKey(DateTime.now().subtract(const Duration(days: 1)));
  final alive = streak.lastDay == today || streak.lastDay == yesterday;
  return MissionProgress.compute(
    scansToday: scansToday,
    streak: alive ? streak.count : 0,
    claimedToday: claimed,
  );
});

final unlockedAchievementsProvider = Provider<Set<String>>((ref) {
  final stats = ref.watch(statsProvider).valueOrNull;
  final streak = ref.watch(streakProvider).valueOrNull ?? StreakState.empty;
  if (stats == null) return const {};
  return AchievementDef.unlocked(stats, streak.count);
});

final scansThisMonthProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(0);
  return ref.watch(gamificationRepositoryProvider).scansThisMonth(uid);
});

final claimedThisMonthProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const <String>{});
  return ref.watch(gamificationRepositoryProvider).claimedThisMonth(uid);
});

final monthlyMissionsProvider = Provider<List<MissionProgress>>((ref) {
  return MissionProgress.computeMonthly(
    scansMonth: ref.watch(scansThisMonthProvider).valueOrNull ?? 0,
    claimedMonth: ref.watch(claimedThisMonthProvider).valueOrNull ?? const {},
  );
});
