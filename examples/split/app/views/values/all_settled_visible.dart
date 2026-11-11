// allSettledVisible: True when there is nothing left to settle in the selected group.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/member_balances.dart';
import 'shared/min_transfers.dart';
import '../../models/sample.dart';

bool allSettledVisible(State state) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final List<Transfer> ts = minTransfers(g.id, g.members, b);
  return ts.isEmpty;
}

void main() {
  test('allSettledVisible', () {
    expect(app.allSettledVisible(sample()), false);
    expect(app.allSettledVisible(sample({'selectedGroup': 'g3'})), true);
  });
}
