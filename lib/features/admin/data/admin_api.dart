import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/json_utils.dart';

/// Thin client for the admin endpoints. The server re-checks admin rights on
/// every call, so hiding the UI is only a convenience, never the protection.
class AdminApi {
  AdminApi(this._b);
  final BackendService _b;

  Future<bool> whoami() async {
    final r = await _b.call('whoami');
    return r['isAdmin'] == true;
  }

  Future<Map<String, Object?>> overview() => _b.call('adminOverview');

  Future<List<Map<String, Object?>>> searchUsers(String q) async {
    final r = await _b.call('adminSearchUsers', {'query': q});
    return _list(r['users']);
  }

  Future<Map<String, Object?>> getUser(String uid) =>
      _b.call('adminGetUser', {'uid': uid});

  Future<void> adjustBalance(String uid, int delta, String reason) =>
      _b.call('adminAdjustBalance',
          {'uid': uid, 'delta': delta, 'reason': reason});

  Future<void> setBan(String uid, bool banned, String reason) => _b.call(
      'adminSetBan', {'uid': uid, 'banned': banned, 'reason': reason});

  Future<void> setPro(String uid, int days) =>
      _b.call('adminSetPro', {'uid': uid, 'days': days});

  Future<void> upsertReward(Map<String, Object?> data) =>
      _b.call('adminUpsertReward', data);

  Future<void> deleteReward(String id) =>
      _b.call('adminDeleteReward', {'id': id});

  Future<void> upsertDevice(Map<String, Object?> data) =>
      _b.call('adminUpsertDevice', data);

  Future<Map<String, Object?>> issueBinCode(String binId, int ttlSeconds) =>
      _b.call('adminIssueBinCode', {'binId': binId, 'ttlSeconds': ttlSeconds});

  Future<List<Map<String, Object?>>> transport() async =>
      _list((await _b.call('adminListTransport'))['requests']);

  Future<void> resolveTransport(String id, bool approve) =>
      _b.call('adminResolveTransport', {'requestId': id, 'approve': approve});

  Future<Map<String, Object?>> lookupCoupon(String code) =>
      _b.call('adminLookupCoupon', {'code': code});

  Future<Map<String, Object?>> redeemCoupon(String code) =>
      _b.call('adminRedeemCoupon', {'code': code});

  Future<void> broadcast(String title, String body) =>
      _b.call('adminBroadcast', {'title': title, 'body': body});

  Future<Map<String, Object?>> stats() => _b.call('adminStats');

  Future<List<Map<String, Object?>>> errors() async =>
      _list((await _b.call('adminErrorLogs'))['errors']);

  static List<Map<String, Object?>> _list(Object? v) =>
      v is List ? v.map(asMap).toList() : const [];
}

final adminApiProvider =
    Provider<AdminApi>((ref) => AdminApi(ref.watch(backendServiceProvider)));

/// True only when the server confirms the signed-in account is an admin.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(uidProvider);
  if (uid == null) return false;
  try {
    return await ref.watch(adminApiProvider).whoami();
  } catch (_) {
    return false;
  }
});

String adminErrorText(Object e) {
  final f = Failure.from(e);
  return f.message.isEmpty ? f.code : '${f.code}: ${f.message}';
}
