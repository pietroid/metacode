// jobAmount formats a single job's amount with thousand separators.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

/// 1234567 -> "1,234,567".
String _jobAmountGroupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

String jobAmount(State state, int index) =>
    '\$${_jobAmountGroupDigits(state.jobs[index].amount)}';

void main() {
  test('jobAmount', () {
    expect(app.jobAmount(sample(), 1), '\$1,200');
  });
}
