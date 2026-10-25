import '../constants/app_constants.dart';

/// Pure form validators. Return a localisation key on error, `null` when valid.
abstract final class Validators {
  static final RegExp _email =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    return _email.hasMatch(s) ? null : 'auth_err_email';
  }

  static String? password(String? v) {
    return (v ?? '').length >= 8 ? null : 'auth_err_password_short';
  }

  static String? passwordMatch(String? v, String other) {
    return v == other ? null : 'auth_err_password_match';
  }

  static String? name(String? v) {
    return (v ?? '').trim().length >= 2 ? null : 'auth_err_name';
  }

  /// BakıKart numbers are 16 digits (spaces allowed in input).
  static String? cardNumber(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\s'), '');
    return RegExp(r'^\d{16}$').hasMatch(digits) ? null : 'transport_err_card';
  }
}

/// Client-side pre-validation of an EP transfer. The server re-validates
/// everything; this only gives fast, friendly feedback.
abstract final class TransferValidator {
  /// Returns a localisation key, or `null` if the transfer looks valid.
  static String? validate({
    required int? amount,
    required int balance,
    required String? senderUid,
    required String? recipientUid,
  }) {
    if (recipientUid == null || recipientUid.isEmpty) {
      return 'transfer_err_recipient';
    }
    if (recipientUid == senderUid) return 'transfer_err_self';
    if (amount == null || amount < AppConstants.minTransferEp) {
      return 'transfer_err_amount';
    }
    if (amount > AppConstants.maxTransferEp) return 'transfer_err_max';
    if (amount > balance) return 'transfer_err_balance';
    return null;
  }
}
