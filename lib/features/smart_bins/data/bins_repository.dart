import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/json_utils.dart';
import '../domain/smart_bin.dart';

class BinsRepository {
  BinsRepository(this._db, this._backend);

  final FirebaseDatabase _db;
  final BackendService _backend;

  Stream<List<SmartBin>> bins() {
    return _db.ref(DbPaths.devices).onValue.map((event) {
      final list = <SmartBin>[];
      for (final child in event.snapshot.children) {
        final key = child.key;
        if (key == null) continue;
        list.add(SmartBin.fromMap(key, asMap(child.value)));
      }
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// Sends a problem report (optionally with a small base64 JPEG photo).
  Future<void> report({
    required String binId,
    required String kind,
    String note = '',
    String? photoBase64,
  }) async {
    await _backend.call('reportBin', {
      'binId': binId,
      'kind': kind,
      'note': note,
      if (photoBase64 != null) 'photo': photoBase64,
    });
  }

  /// Stars / un-stars a bin; the server notifies starred bins when they fill up.
  Future<void> setFavourite(String binId, bool on) async {
    await _backend.call('toggleFavBin', {'binId': binId, 'on': on});
  }

  Stream<Set<String>> favourites(String uid) {
    return _db.ref('users/$uid/favBins').onValue.map((event) {
      final out = <String>{};
      for (final child in event.snapshot.children) {
        final key = child.key;
        if (key != null) out.add(key);
      }
      return out;
    });
  }
}

final binsRepositoryProvider = Provider<BinsRepository>(
  (ref) => BinsRepository(
    ref.watch(databaseProvider),
    ref.watch(backendServiceProvider),
  ),
);

final binsProvider = StreamProvider<List<SmartBin>>(
  (ref) => ref.watch(binsRepositoryProvider).bins(),
);

/// The signed-in person's starred bins.
final favBinsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<String>{});
  return ref.watch(binsRepositoryProvider).favourites(uid);
});

/// Result of asking for the device location.
class LocationState {
  const LocationState._(this.status, this.latitude, this.longitude);
  final LocationStatus status;
  final double? latitude;
  final double? longitude;

  const LocationState.available(double lat, double lng)
      : this._(LocationStatus.available, lat, lng);
  const LocationState.unavailable(LocationStatus s) : this._(s, null, null);

  bool get hasFix => status == LocationStatus.available;

  double? distanceTo(SmartBin bin) {
    if (!hasFix || !bin.hasCoordinates) return null;
    return Geolocator.distanceBetween(
        latitude!, longitude!, bin.lat!, bin.lng!);
  }
}

enum LocationStatus { available, serviceOff, denied, deniedForever, error }

/// Handles service + permission checks, then returns a single position fix.
class LocationController extends AsyncNotifier<LocationState> {
  @override
  Future<LocationState> build() => _resolve(requestPermission: false);

  Future<LocationState> _resolve({required bool requestPermission}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationState.unavailable(LocationStatus.serviceOff);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && requestPermission) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationState.unavailable(LocationStatus.deniedForever);
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.unableToDetermine) {
        return const LocationState.unavailable(LocationStatus.denied);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationState.available(pos.latitude, pos.longitude);
    } catch (_) {
      return const LocationState.unavailable(LocationStatus.error);
    }
  }

  /// Called from the "Enable location" button (shows the system prompt).
  Future<void> request() async {
    state = const AsyncLoading();
    state = AsyncData(await _resolve(requestPermission: true));
  }
}

final locationProvider =
    AsyncNotifierProvider<LocationController, LocationState>(
        LocationController.new);
