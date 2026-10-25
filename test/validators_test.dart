import 'package:ecopoint_pro/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.az'), isNull);
      expect(Validators.email(' user.name+x@mail.co '), isNull);
      expect(Validators.email('nope'), 'auth_err_email');
      expect(Validators.email(null), 'auth_err_email');
    });

    test('password needs 8+ chars', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('passwordMatch / name', () {
      expect(Validators.passwordMatch('a', 'a'), isNull);
      expect(Validators.passwordMatch('a', 'b'), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name(' Al '), isNull);
    });

    test('card number must be 16 digits (spaces allowed)', () {
      expect(Validators.cardNumber('1234 5678 9012 3456'), isNull);
      expect(Validators.cardNumber('1234'), isNotNull);
      expect(Validators.cardNumber('1234 5678 9012 345a'), isNotNull);
    });
  });

  group('TransferValidator', () {
    String? v({int? amount, int balance = 1000, String? me = 'a', String? to = 'b'}) =>
        TransferValidator.validate(
            amount: amount, balance: balance, senderUid: me, recipientUid: to);

    test('valid transfer', () => expect(v(amount: 100), isNull));
    test('missing recipient', () => expect(v(amount: 1, to: ''), 'transfer_err_recipient'));
    test('self transfer', () => expect(v(amount: 1, to: 'a'), 'transfer_err_self'));
    test('zero / null / negative amount', () {
      expect(v(amount: null), 'transfer_err_amount');
      expect(v(amount: 0), 'transfer_err_amount');
      expect(v(amount: -5), 'transfer_err_amount');
    });
    test('over max', () => expect(v(amount: 10001, balance: 99999), 'transfer_err_max'));
    test('over balance', () => expect(v(amount: 500, balance: 100), 'transfer_err_balance'));
    test('exact balance is allowed', () => expect(v(amount: 1000), isNull));
  });
}
