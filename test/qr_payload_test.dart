import 'package:ecopoint_pro/core/utils/qr_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sig = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
  const uid = 'k3JqP9xZ2mN8vB5cL1wT7yU4aD6e';

  group('bin codes', () {
    test('parses a well-formed static code', () {
      final p = QrPayload.parse('EP2:bin-01:$sig');
      expect(p.kind, QrKind.bin);
      expect(p.binId, 'bin-01');
      expect(p.isValid, isTrue);
    });

    test('rejects wrong part count, bad ids, bad signature and old EP1 codes',
        () {
      expect(QrPayload.parse('EP2:bin').kind, QrKind.invalid);
      expect(QrPayload.parse('EP2:bi n:$sig').kind, QrKind.invalid);
      expect(QrPayload.parse('EP2:bin:zz').kind, QrKind.invalid);
      expect(QrPayload.parse('EP1:bin-01:abc123:1900000000:$sig').kind,
          QrKind.invalid);
    });
  });

  group('user codes', () {
    test('prefixed and bare UIDs', () {
      expect(QrPayload.parse('ecopoint:user:$uid').userId, uid);
      expect(QrPayload.parse(uid).kind, QrKind.user);
      expect(QrPayload.parse(QrPayload.forUser(uid)).userId, uid);
    });

    test('rejects short or malformed ids', () {
      expect(QrPayload.parse('ecopoint:user:short').kind, QrKind.invalid);
      expect(QrPayload.parse('hello world').kind, QrKind.invalid);
    });
  });

  test('empty, null and oversized input are invalid', () {
    expect(QrPayload.parse(null).kind, QrKind.invalid);
    expect(QrPayload.parse('   ').kind, QrKind.invalid);
    expect(QrPayload.parse('A' * 300).kind, QrKind.invalid);
  });

  test('a bin payload never yields a user id and vice versa', () {
    expect(QrPayload.parse('EP2:b:$sig').userId, isNull);
    expect(QrPayload.parse(uid).binId, isNull);
  });
}
