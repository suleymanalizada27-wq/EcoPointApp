import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/backend_service.dart';
import '../../../core/services/firebase_providers.dart';
import '../domain/activity_aggregator.dart';
import '../domain/ep_transaction.dart';
import '../domain/impact_estimator.dart';
import '../domain/levels.dart';
import '../domain/wallet_models.dart';
import 'wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(
    ref.watch(databaseProvider),
    ref.watch(backendServiceProvider),
  ),
);

final balanceProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<int>.value(0);
  return ref.watch(walletRepositoryProvider).balance(uid);
});

final statsProvider = StreamProvider<WalletStats>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<WalletStats>.value(WalletStats.empty);
  return ref.watch(walletRepositoryProvider).stats(uid);
});

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<UserProfile?>.value(null);
  return ref.watch(walletRepositoryProvider).profile(uid);
});

final transactionsProvider = StreamProvider<List<EpTransaction>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream<List<EpTransaction>>.value(const []);
  return ref.watch(walletRepositoryProvider).transactions(uid);
});

/// Last-7-days buckets, derived from the live transaction stream.
final weeklyActivityProvider = Provider<AsyncValue<List<DayBucket>>>((ref) {
  return ref.watch(transactionsProvider).whenData(
        (txs) => ActivityAggregator.daily(txs, days: 7, now: DateTime.now()),
      );
});

final levelProgressProvider = Provider<LevelProgress>((ref) {
  final earned = ref.watch(statsProvider).valueOrNull?.earned ?? 0;
  return Levels.forEarned(earned);
});

final impactProvider = Provider<ImpactEstimate>((ref) {
  final scans = ref.watch(statsProvider).valueOrNull?.scans ?? 0;
  return ImpactEstimate.fromScans(scans);
});
