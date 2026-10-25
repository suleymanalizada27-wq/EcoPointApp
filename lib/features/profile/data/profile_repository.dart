import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/json_utils.dart';

class ProfileRepository {
  ProfileRepository(this._db, this._backend);

  final FirebaseDatabase _db;
  final BackendService _backend;

  /// Name / bio / avatar are written by the backend so the public leaderboard
  /// entry stays in sync and values are validated server-side.
  Future<void> updateProfile({
    required String name,
    required String bio,
    required String avatar,
  }) async {
    await _backend.call('updateProfile', {
      'name': name.trim(),
      'bio': bio.trim(),
      'avatar': avatar,
    });
  }

  /// Notification preferences live under `users/{uid}/prefs` (the only part
  /// of the user record clients may write directly).
  Future<void> setPref(String uid, String key, bool value) async {
    try {
      await _db.ref('${DbPaths.prefs(uid)}/$key').set(value);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Returns the EP bonus granted.
  Future<int> applyReferral(String code) async {
    final res = await _backend.call('applyReferral', {'code': code.trim()});
    return asInt(res['bonus']);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(databaseProvider),
    ref.watch(backendServiceProvider),
  ),
);
