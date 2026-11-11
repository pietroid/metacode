// paidByChipSelected: currentMembers[index] equals draftPaidBy.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_group.dart';

bool paidByChipSelected(State state, int index) {
  final members = currentGroup(state).members;
  if (index < 0 || index >= members.length) return false;
  return members[index] == state.draftPaidBy;
}

void main() {
  test('paidByChipSelected', () {
    expect(app.paidByChipSelected(sample(), 0), true);
    expect(app.paidByChipSelected(sample(), 1), false);
  });
}
