// filterMemberOptions: everyone label followed by the selected group's members.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import '../../models/sample.dart';

List<String> filterMemberOptions(State state, Labels labels) {
  final List<String> members = currentGroup(state).members;
  return [labels.everyone, ...members];
}

void main() {
  test('filterMemberOptions', () {
    final o = app.filterMemberOptions(sample());
    expect(o.length, 5);
    expect(o.first, 'Everyone');
  });
}
