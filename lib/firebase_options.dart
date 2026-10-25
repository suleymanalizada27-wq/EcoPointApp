// PLACEHOLDER — regenerate with the FlutterFire CLI:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=ecopoint-b3d60
//
// That command overwrites this file with real Android/iOS app IDs and API keys
// from the existing Firebase project and wires up google-services.json /
// GoogleService-Info.plist. Until then the app shows a "Firebase setup needed"
// screen instead of crashing.
//
// The project-level values below (project id, database URL, bucket, sender id)
// are taken from the existing web app's public client config. The per-platform
// `apiKey` / `appId` are NOT invented here — they must come from your Firebase
// console, so they are marked REPLACE_*.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('This app targets Android and iOS only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDKRzQxbRkkEaHSrQdAjk8Ivl2pi5z5DE',
    appId: '1:814012413122:android:dd80c512779b03eaa1f75b',
    messagingSenderId: '814012413122',
    projectId: 'ecopoint-suleyman-2026',
    databaseURL: 'https://ecopoint-suleyman-2026-default-rtdb.firebaseio.com',
    storageBucket: 'ecopoint-suleyman-2026.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '193692283784',
    projectId: 'ecopoint-b3d60',
    databaseURL: 'https://ecopoint-b3d60-default-rtdb.firebaseio.com',
    storageBucket: 'ecopoint-b3d60.firebasestorage.app',
    iosBundleId: 'az.ecopoint.pro',
  );
}
