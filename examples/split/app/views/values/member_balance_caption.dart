// memberBalanceCaption: getsBack, owes or settled for member index's balance.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/member_balances.dart';
import '../../models/sample.dart';

String memberBalanceCaption(State state, Labels labels, int index) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final num v = b[index];
  if (v > 0.005) return labels.getsBack;
  if (v < -0.005) return labels.owes;
  return labels.settled;
}

void main() {
  test('memberBalanceCaption', () {
    expect(app.memberBalanceCaption(sample(), 0), 'owes');
    expect(app.memberBalanceCaption(sample(), 1), 'gets back');
  });
}
