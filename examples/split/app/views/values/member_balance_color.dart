// memberBalanceColor: Green, coral or grey for member index's balance.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/member_balances.dart';
import '../../models/sample.dart';

String memberBalanceColor(State state, int index) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final num v = b[index];
  if (v > 0.005) return '#2E8B57';
  if (v < -0.005) return '#D9534F';
  return '#7A7F7C';
}

void main() {
  test('memberBalanceColor', () {
    expect(app.memberBalanceColor(sample(), 1), '#2E8B57');
    expect(app.memberBalanceColor(sample(), 0), '#D9534F');
  });
}
