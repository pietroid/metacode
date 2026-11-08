// workTip: Highlights the largest unpaid invoice, or celebrates if all are paid.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String _workTipGroupDigits(num n) {
  final digits = (n < 0 ? 0 - n : n).round().toString();
  var out = n < 0 ? "-" : "";
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out += ',';
    out += digits[i];
  }
  return out;
}

String workTip(State state, Labels labels) {
  Job? biggest;
  for (final j in state.jobs) {
    if (!j.paid && (biggest == null || j.amount > biggest.amount)) biggest = j;
  }
  if (biggest == null) return labels.everyonePaid;
  return '${biggest.client} ${labels.stillOwesYou} \$${_workTipGroupDigits(biggest.amount)}. ${labels.draftReminder}';
}

void main() {
  test('workTip', () {
    expect(app.workTip(sample()), contains('Bakery still owes you \$800'));
  });
}
