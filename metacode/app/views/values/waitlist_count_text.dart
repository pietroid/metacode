// waitlistCountText: The footer text showing the current waitlist count.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String waitlistCountText(State state, Labels labels) =>
    '${_waitlistCountTextGroupDigits(state.waitlistCount)} ${labels.peopleOnTheList}';

String _waitlistCountTextGroupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

void main() {
  test('waitlistCountText', () {
    expect(
      app.waitlistCountText(sample(waitlistCount: 1284)),
      '1,284 people are already on the list',
    );
  });
}
