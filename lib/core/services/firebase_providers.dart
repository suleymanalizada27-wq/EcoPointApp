import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'firebase_bootstrap.dart';

/// Result of Firebase initialisation; overridden in `main()`.
final bootProvider = Provider<BootResult>(
  (ref) => const BootResult(BootStatus.needsSetup),
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final databaseProvider = Provider<FirebaseDatabase>(
  (ref) => FirebaseDatabase.instance,
);

/// Emits the signed-in user (and re-emits when the profile changes).
final authUserProvider = StreamProvider<User?>((ref) {
  final boot = ref.watch(bootProvider);
  if (!boot.isReady) return Stream<User?>.value(null);
  final auth = ref.watch(firebaseAuthProvider);
  // Start from the already-restored user so a cold start never flashes the
  // sign-in screen, then follow live changes.
  return (() async* {
    yield auth.currentUser;
    yield* auth.userChanges();
  })();
});

/// Current UID or `null` while signed out / loading.
final uidProvider = Provider<String?>((ref) {
  return ref.watch(authUserProvider).valueOrNull?.uid;
});

/// True when the Realtime Database socket is connected.
final connectionProvider = StreamProvider<bool>((ref) {
  final boot = ref.watch(bootProvider);
  if (!boot.isReady) return Stream<bool>.value(true);
  final db = ref.watch(databaseProvider);
  return db
      .ref(DbPaths.connectionState)
      .onValue
      .map((event) => event.snapshot.value == true);
});
