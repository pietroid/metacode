// taxText: Calculates the tax reserve from the received amount and tax rate.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String _taxTextGroupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

num _taxTextReceived(State state) {
  num total = 0;
  for (final j in state.jobs) {
    if (j.paid) total += j.amount;
  }
  return total;
}

String taxText(State state, Labels labels) {
  final reserve = _taxTextReceived(state) * state.taxRate / 100;
  return '${labels.setAside} ${state.taxRate.round()}% ${labels.forTaxes} \$${_taxTextGroupDigits(reserve)}';
}

void main() {
  test('taxText', () {
    expect(app.taxText(sample()), 'Set aside 10% for taxes: \$120');
  });
}
