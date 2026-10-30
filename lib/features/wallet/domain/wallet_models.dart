import '../../../core/utils/json_utils.dart';

/// `users/{uid}/stats`. `earned`, `sent`, `scans` exist in the legacy schema;
/// `spent` is maintained by the new backend (0 on legacy accounts).
class WalletStats {
  const WalletStats({
    this.earned = 0,
    this.sent = 0,
    this.scans = 0,
    this.spent = 0,
  });

  final int earned;
  final int sent;
  final int scans;
  final int spent;

  static const WalletStats empty = WalletStats();

  factory WalletStats.fromMap(Map<String, Object?> m) => WalletStats(
        earned: asInt(m['earned']),
        sent: asInt(m['sent']),
        scans: asInt(m['scans']),
        spent: asInt(m['spent']),
      );
}

/// `users/{uid}` profile fields the app displays.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.name = '',
    this.email = '',
    this.photoUrl = '',
    this.bio = '',
    this.avatar = '',
    this.referralCode = '',
    this.referredBy = '',
    this.isPro = false,
    this.proExpiry,
    this.notifyActivity = true,
    this.notifyNews = true,
    this.notifyOffers = true,
  });

  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String bio;
  final String avatar;
  final String referralCode;
  final String referredBy;
  final bool isPro;
  final DateTime? proExpiry;
  final bool notifyActivity;
  final bool notifyNews;
  final bool notifyOffers;

  /// Pro is active only while not expired (the legacy flag never expired).
  bool isProAt(DateTime now) {
    if (!isPro) return false;
    final e = proExpiry;
    return e == null || e.isAfter(now);
  }

  bool get hasReferrer => referredBy.isNotEmpty;

  String get firstName {
    final n = name.trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  factory UserProfile.fromMap(String uid, Map<String, Object?> m) {
    final prefs = asMap(m['prefs']);
    final exp = asInt(m['proExpiry']);
    return UserProfile(
      uid: uid,
      name: asString(m['name']),
      email: asString(m['email']),
      photoUrl: asString(m['photoURL']),
      bio: asString(m['bio']),
      avatar: asString(m['avatar']),
      referralCode: asString(m['referralCode']),
      referredBy: asString(m['referredBy']),
      isPro: asBool(m['isPro']),
      proExpiry: exp > 0 ? DateTime.fromMillisecondsSinceEpoch(exp) : null,
      notifyActivity: prefs['notifyActivity'] == null
          ? true
          : asBool(prefs['notifyActivity']),
      notifyNews:
          prefs['notifyNews'] == null ? true : asBool(prefs['notifyNews']),
      notifyOffers: prefs['notifyOffers'] == null
          ? true
          : asBool(prefs['notifyOffers']),
    );
  }
}
