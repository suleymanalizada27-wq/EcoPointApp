/// App-wide constants.
///
/// Business constants that gate EP (limits, multipliers, rates) are duplicated
/// in the Cloud Functions, which are the source of truth. The values here are
/// used only for *client-side pre-validation and display*.
abstract final class AppConstants {
  static const String appName = 'EcoPoint';
  /// Keep in sync with pubspec.yaml `version`.
  static const String appVersion = '1.0.0';
  /// Base URL of the Node backend (see firebase/functions + README). Override
  /// at build time:  --dart-define=BACKEND_URL=https://your-service.onrender.com
  /// OAuth *web* client id of the Firebase project (Authentication → Sign-in
  /// method → Google → Web SDK configuration). Needed so Google sign-in
  /// returns an ID token Firebase accepts:
  ///   --dart-define=GOOGLE_WEB_CLIENT_ID=1234-abc.apps.googleusercontent.com
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
  static const String androidPackage = 'az.ecopoint.pro';

  static const String partnerSiteUrl =
      'https://greenlinegroupazerbaijan2026.netlify.app/';
  static const String presentationUrl =
      'https://gamma.app/docs/EcoPoint-Agll-Zibil-Daha-Cox-Mukafat-vvx39v1c26436s1';

  /// Firebase project this app belongs to (the existing web app's project).
  static const String firebaseProjectId = 'ecopoint-b3d60';
  static const String databaseUrl =
      'https://ecopoint-b3d60-default-rtdb.firebaseio.com';

  /// OpenStreetMap raster tiles — no API key required.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Fallback map centre (Baku) used only when the user location is unknown.
  static const double defaultLat = 40.4093;
  static const double defaultLng = 49.8671;
  static const double defaultZoom = 12;

  // ── Limits mirrored from the legacy app / backend ──
  static const int maxTransferEp = 10000;
  static const int minTransferEp = 1;
  static const int minCouponEp = 300;
  static const int transportMinEp = 100;
  static const int referralBonusEp = 200;
  static const int streakBonusEp = 50;
  static const int streakBonusEveryDays = 7;
  static const int binOnlineWindowSeconds = 60;
  static const int binFullWarningPercent = 80;

  /// How many transactions are streamed for lists / charts.
  static const int txWindow = 200;
}

/// Realtime Database paths. Matches the schema used by the existing web app.
abstract final class DbPaths {
  static String user(String uid) => 'users/$uid';
  static String balance(String uid) => 'users/$uid/balance';
  static String stats(String uid) => 'users/$uid/stats';
  static String transactions(String uid) => 'users/$uid/transactions';
  static String purchases(String uid) => 'users/$uid/purchases';
  static String coupons(String uid) => 'users/$uid/coupons';
  static String streak(String uid) => 'users/$uid/streak';
  static String claims(String uid) => 'users/$uid/claims';
  static String userNotifications(String uid) => 'users/$uid/notifications';
  static String prefs(String uid) => 'users/$uid/prefs';
  static String profile(String uid) => 'users/$uid';
  static const String devices = 'devices';
  static const String rewards = 'rewards';
  static const String leaderboard = 'leaderboard';
  static const String weeklyBoard = 'weeklyBoard';
  static const String globalNotifications = 'globalNotifications';
  static const String connectionState = '.info/connected';
}
