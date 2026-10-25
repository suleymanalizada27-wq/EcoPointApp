import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/utils/json_utils.dart';
import '../domain/ep_transaction.dart';
import '../domain/wallet_models.dart';

/// Lightweight user record returned by recipient search (no balances).
class UserSummary {
  const UserSummary({required this.uid, required this.name, this.photoUrl});
  final String uid;
  final String name;
  final String? photoUrl;
}

class TransferReceipt {
  const TransferReceipt({
    required this.transferId,
    required this.balance,
    required this.recipientName,
    required this.amount,
  });
  final String transferId;
  final int balance;
  final String recipientName;
  final int amount;
}

/// Read access to the signed-in user's wallet (live from Realtime Database)
/// and EP transfers (through the secure backend).
class WalletRepository {
  WalletRepository(this._db, this._backend);

  final FirebaseDatabase _db;
  final BackendService _backend;

  Stream<int> balance(String uid) => _db
      .ref(DbPaths.balance(uid))
      .onValue
      .map((e) => asInt(e.snapshot.value));

  Stream<WalletStats> stats(String uid) => _db
      .ref(DbPaths.stats(uid))
      .onValue
      .map((e) => WalletStats.fromMap(asMap(e.snapshot.value)));

  Stream<UserProfile> profile(String uid) => _db
      .ref(DbPaths.profile(uid))
      .onValue
      .map((e) => UserProfile.fromMap(uid, asMap(e.snapshot.value)));

  /// Newest-first transactions. Push IDs are time-ordered, so
  /// `limitToLast` needs no extra index.
  Stream<List<EpTransaction>> transactions(
    String uid, {
    int limit = AppConstants.txWindow,
  }) {
    return _db
        .ref(DbPaths.transactions(uid))
        .limitToLast(limit)
        .onValue
        .map((event) {
      final list = <EpTransaction>[];
      for (final child in event.snapshot.children) {
        final key = child.key;
        if (key == null) continue;
        list.add(EpTransaction.fromMap(key, asMap(child.value)));
      }
      list.sort((a, b) => b.time.compareTo(a.time));
      return list;
    });
  }

  /// Search by display-name prefix or exact user ID. Served by the backend so
  /// clients never read other users' records (and never see their balances).
  Future<List<UserSummary>> lookupUsers(String query) async {
    final res = await _backend.call('lookupUsers', {'query': query.trim()});
    final raw = res['users'];
    if (raw is! List) return const [];
    return raw
        .map((e) => asMap(e))
        .where((m) => asString(m['uid']).isNotEmpty)
        .map((m) => UserSummary(
              uid: asString(m['uid']),
              name: asString(m['name'], '—'),
              photoUrl: asString(m['photoURL']).isEmpty
                  ? null
                  : asString(m['photoURL']),
            ))
        .toList();
  }

  /// Atomic server-side transfer. [requestId] makes retries idempotent.
  Future<TransferReceipt> transfer({
    required String recipientUid,
    required int amount,
    required String requestId,
  }) async {
    final res = await _backend.call('transferEp', {
      'recipientUid': recipientUid,
      'amount': amount,
      'requestId': requestId,
    });
    return TransferReceipt(
      transferId: asString(res['transferId']),
      balance: asInt(res['balance']),
      recipientName: asString(res['recipientName'], '—'),
      amount: asInt(res['amount'], amount),
    );
  }
}
