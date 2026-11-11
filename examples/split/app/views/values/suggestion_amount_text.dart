// suggestionAmountText: Suggested transfer index's amount via formatUsd.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/format_usd.dart';
import 'shared/member_balances.dart';
import 'shared/min_transfers.dart';
import '../../models/sample.dart';

String suggestionAmountText(State state, int index) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final List<Transfer> ts = minTransfers(g.id, g.members, b);
  return formatUsd(ts[index].amount);
}

void main() {
  test('suggestionAmountText', () {
    expect(app.suggestionAmountText(sample(), 0), '\$140.00');
  });
}
