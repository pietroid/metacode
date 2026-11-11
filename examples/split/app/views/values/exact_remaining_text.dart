// exactRemainingText: '$4.00 left to assign' or '$4.00 over the total'.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_usd.dart';
import 'shared/parse_amount.dart';

String exactRemainingText(State state, Labels labels) {
  num sum = 0;
  for (final String t in state.draftExact) {
    sum += parseAmount(t);
  }
  final num diff = parseAmount(state.draftAmount) - sum;
  if (diff >= 0) return '${formatUsd(diff)} ${labels.left}';
  return '${formatUsd(diff)} ${labels.over}';
}

void main() {
  test('exactRemainingText', () {
    final s = sample({'draftMode': 'exact', 'draftAmount': '50', 'draftExact': ['20', '26', '', '']});
    expect(app.exactRemainingText(s), '\$4.00 left to assign');
    final o = sample({'draftMode': 'exact', 'draftAmount': '50', 'draftExact': ['20', '34', '', '']});
    expect(app.exactRemainingText(o), '\$4.00 over the total');
  });
}
