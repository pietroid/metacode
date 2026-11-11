// filterMemberOptionSelected: Index 0 when filterMember is empty, else the option equal to filterMember.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import '../../models/sample.dart';

bool filterMemberOptionSelected(State state, int index) {
  if (index == 0) return state.filterMember.isEmpty;
  return currentGroup(state).members[index - 1] == state.filterMember;
}

void main() {
  test('filterMemberOptionSelected', () {
    expect(app.filterMemberOptionSelected(sample(), 0), true);
    expect(app.filterMemberOptionSelected(sample({'filterMember': 'Ben'}), 2), true);
    expect(app.filterMemberOptionSelected(sample({'filterMember': 'Ben'}), 0), false);
  });
}
