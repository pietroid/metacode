// filterMemberOptionText: Option index of filterMemberOptions.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import '../../models/sample.dart';

String filterMemberOptionText(State state, Labels labels, int index) {
  if (index == 0) return labels.everyone;
  return currentGroup(state).members[index - 1];
}

void main() {
  test('filterMemberOptionText', () {
    expect(app.filterMemberOptionText(sample(), 0), 'Everyone');
    expect(app.filterMemberOptionText(sample(), 1), 'Ana');
  });
}
