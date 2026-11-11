// memberIsMe: Whether currentMembers[index] is myMember for the selected group.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/my_member.dart';
import '../../models/sample.dart';

bool memberIsMe(State state, int index) {
  final Group g = currentGroup(state);
  return g.members[index] == myMember(state, g.id);
}

void main() {
  test('memberIsMe', () {
    expect(app.memberIsMe(sample(), 0), true);
    expect(app.memberIsMe(sample(), 1), false);
  });
}
