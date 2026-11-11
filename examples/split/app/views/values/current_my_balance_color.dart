// currentMyBalanceColor: Green, coral or grey for my balance in the selected group.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/member_balances.dart';
import 'shared/my_member.dart';
import '../../models/sample.dart';

String currentMyBalanceColor(State state) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final int i = g.members.indexOf(myMember(state, g.id));
  num v = 0;
  if (i >= 0) v = b[i];
  if (v > 0.005) return '#2E8B57';
  if (v < -0.005) return '#D9534F';
  return '#7A7F7C';
}

void main() {
  test('currentMyBalanceColor', () {
    expect(app.currentMyBalanceColor(sample()), '#D9534F');
    expect(app.currentMyBalanceColor(sample({'selectedGroup': 'g3'})), '#7A7F7C');
  });
}
