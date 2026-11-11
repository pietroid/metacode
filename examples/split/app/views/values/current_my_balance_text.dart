// currentMyBalanceText: My balance in the selected group: youAreOwed or youOwe with the amount, or settledUp.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/format_usd.dart';
import 'shared/member_balances.dart';
import 'shared/my_member.dart';
import '../../models/sample.dart';

String currentMyBalanceText(State state, Labels labels) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final int i = g.members.indexOf(myMember(state, g.id));
  num v = 0;
  if (i >= 0) v = b[i];
  if (v > 0.005) return '${labels.youAreOwed} ${formatUsd(v)}';
  if (v < -0.005) return '${labels.youOwe} ${formatUsd(v)}';
  return labels.settledUp;
}

void main() {
  test('currentMyBalanceText', () {
    expect(app.currentMyBalanceText(sample()), 'You owe \$140.00');
    expect(app.currentMyBalanceText(sample({'selectedGroup': 'g3'})), 'Settled up');
  });
}
