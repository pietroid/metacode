// groupList: The shared groups.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Group> groupList(State state) => state.groups;

void main() {
  test('groupList', () {
    final groups = app.groupList(sample());
    expect(groups.length, 3);
    expect(groups[0].name, 'Lisbon trip');
  });
}
