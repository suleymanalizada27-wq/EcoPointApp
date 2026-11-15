import 'package:ecopoint_pro/core/services/update_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compares dotted versions numerically', () {
    expect(isNewerVersion('1.10.0', '1.9.3'), isTrue);
    expect(isNewerVersion('1.0.1', '1.0.0'), isTrue);
    expect(isNewerVersion('2.0', '1.9.9'), isTrue);
    expect(isNewerVersion('1.0.0', '1.0.0'), isFalse);
    expect(isNewerVersion('1.0.0+5', '1.0.0'), isFalse);
    expect(isNewerVersion('0.9.9', '1.0.0'), isFalse);
    expect(isNewerVersion('abc', '1.0.0'), isFalse);
  });
}
