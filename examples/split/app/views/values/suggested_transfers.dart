// suggestedTransfers: minTransfers for the selected group's balances.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/member_balances.dart';
import 'shared/min_transfers.dart';
import '../../models/sample.dart';

List<Transfer> suggestedTransfers(State state) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final List<Transfer> ts = minTransfers(g.id, g.members, b);
  return ts;
}

void main() {
  test('suggestedTransfers', () {
    final ts = app.suggestedTransfers(sample());
    expect(ts.length, 3);
    expect(ts.first.from, 'Ana');
    expect(ts.first.to, 'Ben');
    expect(ts.first.amount, 140);
  });
}
