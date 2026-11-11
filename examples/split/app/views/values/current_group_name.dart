// currentGroupName: The selected group's name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import '../../models/sample.dart';

String currentGroupName(State state) => currentGroup(state).name;

void main() {
  test('currentGroupName', () {
    expect(app.currentGroupName(sample()), 'Lisbon trip');
  });
}
