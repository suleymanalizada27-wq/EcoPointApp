import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

enum BootStatus {
  /// Firebase initialised and ready.
  ready,

  /// Placeholder credentials detected — show the setup screen.
  needsSetup,

  /// Initialisation threw; see [BootResult.error].
  failed,
}

class BootResult {
  const BootResult(this.status, [this.error]);
  final BootStatus status;
  final String? error;
  bool get isReady => status == BootStatus.ready;
}

/// Local development against the Firebase Emulator Suite (no cloud project,
/// no billing). Enable with:
///   flutter run --dart-define=USE_EMULATOR=true [--dart-define=EMULATOR_HOST=192.168.x.x]
/// `10.0.2.2` is the host machine as seen from the Android emulator; use your
/// PC's LAN IP for a physical phone.
const bool kUseEmulator = bool.fromEnvironment('USE_EMULATOR');
const String kEmulatorHost =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

const FirebaseOptions _emulatorOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:android:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-ecopoint',
  databaseURL: 'https://demo-ecopoint-default-rtdb.firebaseio.com',
);

abstract final class FirebaseBootstrap {
  /// Initialises Firebase unless the options are still the placeholder ones.
  static Future<BootResult> init() async {
    try {
      if (kUseEmulator) {
        await Firebase.initializeApp(options: _emulatorOptions);
        await FirebaseAuth.instance.useAuthEmulator(kEmulatorHost, 9099);
        FirebaseDatabase.instance.useDatabaseEmulator(kEmulatorHost, 9000);
        return const BootResult(BootStatus.ready);
      }
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options.apiKey.startsWith('REPLACE') ||
          options.appId.startsWith('REPLACE')) {
        return const BootResult(BootStatus.needsSetup);
      }
      await Firebase.initializeApp(options: options);

      // Offline cache so balance / history render instantly and survive
      // flaky connectivity. Must be configured before the first DB use.
      if (!kIsWeb) {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        FirebaseDatabase.instance.setPersistenceCacheSizeBytes(20 * 1024 * 1024);
      }
      return const BootResult(BootStatus.ready);
    } on UnsupportedError catch (e) {
      return BootResult(BootStatus.failed, e.message);
    } catch (e) {
      return BootResult(BootStatus.failed, e.toString());
    }
  }
}
