// currentMembers: The selected group's members.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import '../../models/sample.dart';

List<String> currentMembers(State state) => currentGroup(state).members;

void main() {
  test('currentMembers', () {
    expect(app.currentMembers(sample()), ['Ana', 'Ben', 'Carla', 'Dev']);
  });
}
