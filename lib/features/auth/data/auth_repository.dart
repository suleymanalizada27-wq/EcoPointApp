import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/services/session_restore.dart';

/// Maps a Firebase Auth error code to a localisation key.
String authErrorKey(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'invalid-login-credentials':
      return 'auth_err_invalid_credential';
    case 'user-not-found':
      return 'auth_err_user_not_found';
    case 'email-already-in-use':
      return 'auth_err_email_in_use';
    case 'weak-password':
      return 'auth_err_weak_password';
    case 'too-many-requests':
      return 'auth_err_too_many';
    case 'network-request-failed':
    case Failure.network:
      return 'auth_err_network';
    case 'user-disabled':
      return 'auth_err_disabled';
    case 'invalid-email':
      return 'auth_err_email';
    case 'requires-recent-login':
      return 'auth_err_recent_login';
    case 'google-unavailable':
      return 'auth_err_google_unavailable';
    default:
      return 'error_generic';
  }
}

/// Wraps Firebase Authentication. Throws [Failure] with Auth codes.
class AuthRepository {
  AuthRepository(this._auth, this._backend);

  final FirebaseAuth _auth;
  final BackendService _backend;

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await SessionRestore.remember(google: false);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      await cred.user?.reload();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw Failure.from(e);
    }
  }

  GoogleSignIn _google() => GoogleSignIn(
        serverClientId: AppConstants.googleWebClientId.isEmpty
            ? null
            : AppConstants.googleWebClientId,
      );

  /// Returns false if the user dismissed the Google account picker.
  Future<bool> signInWithGoogle() async {
    if (AppConstants.googleWebClientId.isEmpty) {
      // Build without --dart-define=GOOGLE_WEB_CLIENT_ID: Google would return
      // no ID token and Firebase would reject the sign-in.
      throw const Failure('google-unavailable');
    }
    try {
      final account = await _google().signIn();
      if (account == null) return false;
      final tokens = await account.authentication;
      if (tokens.idToken == null) throw const Failure('google-unavailable');
      final credential = GoogleAuthProvider.credential(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
      );
      await _auth.signInWithCredential(credential);
      await SessionRestore.remember(google: true);
      return true;
    } on Failure {
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return false;
      if (e.code == 'network_error') throw const Failure(Failure.network);
      // sign_in_failed / developer error: SHA key or client id not registered.
      throw const Failure('google-unavailable');
    } catch (e) {
      final f = Failure.from(e);
      // Platform channel errors mean google-services config is missing.
      if (f.code == Failure.unknown) {
        throw const Failure('google-unavailable');
      }
      throw f;
    }
  }

  Future<void> signOut() async {
    await SessionRestore.remember(google: false);
    try {
      await _google().signOut();
    } catch (_) {
      // Not signed in with Google — ignore.
    }
    await _auth.signOut();
  }

  /// Deletes server data first (profile, balance, history), then the auth
  /// user. If Firebase asks for a recent login the caller must re-authenticate.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw const Failure(Failure.unauthenticated);
    await SessionRestore.remember(google: false);
    await _backend.call('deleteAccountData');
    try {
      await user.delete();
    } catch (e) {
      throw Failure.from(e);
    }
    try {
      await _google().signOut();
    } catch (_) {}
  }

  /// Creates / refreshes the server-side profile (referral code, leaderboard
  /// entry). Safe to call repeatedly.
  Future<void> ensureProfile() async {
    await _backend.call('ensureProfile');
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(backendServiceProvider),
  ),
);

/// Runs `ensureProfile` once per signed-in uid. Failure is non-fatal (the
/// backend may not be deployed yet) — it is retried on next app start.
final profileBootstrapProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(uidProvider);
  if (uid == null) return;
  try {
    await ref.read(authRepositoryProvider).ensureProfile();
  } catch (_) {
    // Swallow: UI features that need the backend report their own errors.
  }
});
