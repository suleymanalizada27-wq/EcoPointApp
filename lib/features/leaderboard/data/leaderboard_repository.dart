import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/json_utils.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.ep,
    this.photoUrl,
    this.avatar,
  });
  final String uid;
  final String name;
  final int ep;
  final String? photoUrl;
  final String? avatar;
}

/// Reads the public `leaderboard/{uid}` projection (name, photo, EP) kept in
/// sync by the backend — so clients never need to read other users' private
/// records (the legacy app scanned the whole `users` node).
class LeaderboardRepository {
  LeaderboardRepository(this._db);
  final FirebaseDatabase _db;

  /// Monday (yyyy-MM-dd) of the current Baku (UTC+4) week — must match the
  /// backend's `weekKey()`.
  static String currentWeekKey([DateTime? now]) {
    final ms = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch +
        4 * 3600 * 1000;
    final dn = ms ~/ 86400000;
    final monday = dn - ((dn + 3) % 7);
    final d = DateTime.fromMillisecondsSinceEpoch(monday * 86400000, isUtc: true);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Stream<List<LeaderboardEntry>> top({int limit = 20}) =>
      _watch(_db.ref(DbPaths.leaderboard), limit);

  Stream<List<LeaderboardEntry>> weekly({int limit = 20}) => _watch(
      _db.ref('${DbPaths.weeklyBoard}/${currentWeekKey()}'), limit);

  Stream<List<LeaderboardEntry>> _watch(DatabaseReference ref, int limit) {
    return ref
        .orderByChild('ep')
        .limitToLast(limit)
        .onValue
        .map((event) {
      final list = <LeaderboardEntry>[];
      for (final c in event.snapshot.children) {
        final m = asMap(c.value);
        final ep = asInt(m['ep']);
        if (ep <= 0) continue;
        list.add(LeaderboardEntry(
          uid: c.key ?? '',
          name: asString(m['name'], '—'),
          ep: ep,
          photoUrl:
              asString(m['photoURL']).isEmpty ? null : asString(m['photoURL']),
          avatar: asString(m['avatar']).isEmpty ? null : asString(m['avatar']),
        ));
      }
      list.sort((a, b) => b.ep.compareTo(a.ep));
      return list;
    });
  }
}

final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>(
  (ref) => LeaderboardRepository(ref.watch(databaseProvider)).top(),
);

final weeklyLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>(
  (ref) => LeaderboardRepository(ref.watch(databaseProvider)).weekly(),
);
