// exactRemainingVisible: exact mode and the amounts differ from the total by over half a cent.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/parse_amount.dart';

bool exactRemainingVisible(State state) {
  if (state.draftMode != SplitMode.exact) return false;
  num sum = 0;
  for (final String t in state.draftExact) {
    sum += parseAmount(t);
  }
  final num diff = parseAmount(state.draftAmount) - sum;
  return diff.abs() > 0.005;
}

void main() {
  test('exactRemainingVisible', () {
    expect(app.exactRemainingVisible(sample()), false);
    final s = sample({'draftMode': 'exact', 'draftAmount': '50', 'draftExact': ['20', '26', '', '']});
    expect(app.exactRemainingVisible(s), true);
    final ok = sample({'draftMode': 'exact', 'draftAmount': '50', 'draftExact': ['20', '30', '', '']});
    expect(app.exactRemainingVisible(ok), false);
  });
}
