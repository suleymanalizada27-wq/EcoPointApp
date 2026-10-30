import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Some phones (aggressive task killers) lose Firebase's stored session when
/// the app is swiped away. For people who signed in with Google we remember
/// that fact and quietly sign them back in at start-up. Password users still
/// have to sign in again — we never store passwords.
abstract final class SessionRestore {
  static const String _key = 'ep-google-session';

  static Future<void> remember({required bool google}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, google);
    } catch (_) {}
  }

  /// Returns true when a lost session had to be restored.
  static Future<bool> restoreIfLost() async {
    try {
      final auth = FirebaseAuth.instance;
      var user = auth.currentUser;
      user ??= await auth
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (user != null) return false;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_key) != true) return false;
      if (AppConstants.googleWebClientId.isEmpty) return false;

      final account = await GoogleSignIn(
        serverClientId: AppConstants.googleWebClientId,
      ).signInSilently();
      if (account == null) return false;
      final tokens = await account.authentication;
      if (tokens.idToken == null) return false;
      await auth.signInWithCredential(GoogleAuthProvider.credential(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }
}
