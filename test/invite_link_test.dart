import 'package:flutter_test/flutter_test.dart';

import 'package:ecopoint_pro/core/services/invite_link.dart';

void main() {
  test('parseInviteCode normalises and validates', () {
    expect(parseInviteCode('abcd-234'), 'ABCD234');
    expect(parseInviteCode('ABCD234'), 'ABCD234');
    expect(parseInviteCode('ab'), isNull);
    expect(parseInviteCode('<script>'), 'SCRIPT');
    expect(parseInviteCode('A' * 13), isNull);
  });
}
