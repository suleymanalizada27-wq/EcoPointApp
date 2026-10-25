import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/json_utils.dart';
import '../domain/reward.dart';
import '../domain/reward_catalog.dart';

/// Rewards plus a flag telling the UI the built-in fallback is being shown.
class RewardList {
  const RewardList(this.items, {required this.isFallback});
  final List<Reward> items;
  final bool isFallback;
}

class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.name,
    required this.ep,
    required this.time,
    this.code,
    this.status,
  });
  final String id;
  final String name;
  final int ep;
  final DateTime time;

  /// Coupon code, when the purchase was a coupon.
  final String? code;

  /// e.g. `pending` for BakıKart requests awaiting the partner.
  final String? status;
}

class PurchaseReceipt {
  const PurchaseReceipt({required this.balance, this.code, this.azn});
  final int balance;
  final String? code;
  final double? azn;
}

class MarketplaceRepository {
  MarketplaceRepository(this._db, this._backend);

  final FirebaseDatabase _db;
  final BackendService _backend;

  /// Server catalog if present, otherwise the built-in legacy catalog.
  Stream<RewardList> rewards() {
    return _db.ref(DbPaths.rewards).onValue.map((event) {
      final out = <Reward>[];
      for (final child in event.snapshot.children) {
        final key = child.key;
        if (key == null) continue;
        final r = Reward.fromMap(key, asMap(child.value));
        if (r.ep > 0 && r.names.isNotEmpty) out.add(r);
      }
      if (out.isEmpty) {
        return RewardList(RewardCatalog.builtIn, isFallback: true);
      }
      return RewardList(out.where((r) => r.active).toList(),
          isFallback: false);
    });
  }

  Stream<List<PurchaseRecord>> purchases(String uid) {
    return _db.ref(DbPaths.purchases(uid)).limitToLast(100).onValue.map((e) {
      final list = <PurchaseRecord>[];
      for (final c in e.snapshot.children) {
        final m = asMap(c.value);
        list.add(PurchaseRecord(
          id: c.key ?? '',
          name: asString(m['name']),
          ep: asInt(m['price']),
          time: DateTime.fromMillisecondsSinceEpoch(asInt(m['ts'])),
          code: asString(m['code']).isEmpty ? null : asString(m['code']),
          status: asString(m['status']).isEmpty ? null : asString(m['status']),
        ));
      }
      list.sort((a, b) => b.time.compareTo(a.time));
      return list;
    });
  }

  Future<PurchaseReceipt> purchase({
    required String rewardId,
    required String requestId,
  }) async {
    final res = await _backend.call('purchaseReward', {
      'rewardId': rewardId,
      'requestId': requestId,
    });
    return PurchaseReceipt(balance: asInt(res['balance']));
  }

  Future<PurchaseReceipt> createCoupon({
    required String partnerId,
    required int ep,
    required String requestId,
  }) async {
    final res = await _backend.call('createCoupon', {
      'partnerId': partnerId,
      'ep': ep,
      'requestId': requestId,
    });
    return PurchaseReceipt(
      balance: asInt(res['balance']),
      code: asString(res['code']),
      azn: asDouble(res['azn']),
    );
  }

  Future<PurchaseReceipt> requestTransportTopUp({
    required String cardNumber,
    required int ep,
    required String requestId,
  }) async {
    final res = await _backend.call('requestTransportTopUp', {
      'cardNumber': cardNumber.replaceAll(RegExp(r'\s'), ''),
      'ep': ep,
      'requestId': requestId,
    });
    return PurchaseReceipt(balance: asInt(res['balance']));
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MarketplaceRepository(
    ref.watch(databaseProvider),
    ref.watch(backendServiceProvider),
  ),
);

final rewardsProvider = StreamProvider<RewardList>(
  (ref) => ref.watch(marketplaceRepositoryProvider).rewards(),
);

final purchasesProvider = StreamProvider<List<PurchaseRecord>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const <PurchaseRecord>[]);
  return ref.watch(marketplaceRepositoryProvider).purchases(uid);
});
