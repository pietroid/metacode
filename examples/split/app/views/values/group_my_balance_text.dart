// groupMyBalanceText: My balance in group index: youAreOwed or youOwe with the amount, or settledUp within half a cent.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/format_usd.dart';
import 'shared/member_balances.dart';
import 'shared/my_member.dart';
import '../../models/sample.dart';

String groupMyBalanceText(State state, Labels labels, int index) {
  final Group g = state.groups[index];
  final List<num> b = memberBalances(state, g.id, g.members);
  final int i = g.members.indexOf(myMember(state, g.id));
  num v = 0;
  if (i >= 0) v = b[i];
  if (v > 0.005) return '${labels.youAreOwed} ${formatUsd(v)}';
  if (v < -0.005) return '${labels.youOwe} ${formatUsd(v)}';
  return labels.settledUp;
}

void main() {
  test('groupMyBalanceText', () {
    expect(app.groupMyBalanceText(sample(), 0), 'You owe \$140.00');
    expect(app.groupMyBalanceText(sample(), 1), 'You are owed \$11.20');
    expect(app.groupMyBalanceText(sample(), 2), 'Settled up');
  });
}
