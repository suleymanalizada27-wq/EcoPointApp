import 'package:flutter/foundation.dart';

/// Invite code received through an App Link (`/invite/<code>`) that has not
/// been used yet. The router stores it, the main shell opens the referral
/// screen, which pre-fills the field and clears it.
final ValueNotifier<String?> pendingInviteCode = ValueNotifier<String?>(null);

/// Upper-case letters/digits only, 4–12 long; otherwise null.
String? parseInviteCode(String raw) {
  final code = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return code.length >= 4 && code.length <= 12 ? code : null;
}
