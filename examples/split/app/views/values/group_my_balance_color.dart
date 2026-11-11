// groupMyBalanceColor: Green when owed, coral when I owe, grey when settled, for group index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/member_balances.dart';
import 'shared/my_member.dart';
import '../../models/sample.dart';

String groupMyBalanceColor(State state, int index) {
  final Group g = state.groups[index];
  final List<num> b = memberBalances(state, g.id, g.members);
  final int i = g.members.indexOf(myMember(state, g.id));
  num v = 0;
  if (i >= 0) v = b[i];
  if (v > 0.005) return '#2E8B57';
  if (v < -0.005) return '#D9534F';
  return '#7A7F7C';
}

void main() {
  test('groupMyBalanceColor', () {
    expect(app.groupMyBalanceColor(sample(), 0), '#D9534F');
    expect(app.groupMyBalanceColor(sample(), 1), '#2E8B57');
    expect(app.groupMyBalanceColor(sample(), 2), '#7A7F7C');
  });
}
