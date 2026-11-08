// receivedText: The total amount received from paid jobs.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

/// 1234567 -> "1,234,567".
String _receivedTextGroupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

num _receivedTextReceived(State state) {
  num total = 0;
  for (final j in state.jobs) {
    if (j.paid) total += j.amount;
  }
  return total;
}

String receivedText(State state) =>
    '\$${_receivedTextGroupDigits(_receivedTextReceived(state))}';

void main() {
  test('receivedText', () {
    expect(app.receivedText(app.initialState), '\$1,550');
    expect(app.receivedText(sample()), '\$1,200');
  });
}
