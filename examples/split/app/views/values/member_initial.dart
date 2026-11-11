// memberInitial: First letter of currentMembers[index].

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import '../../models/sample.dart';

String memberInitial(State state, int index) => currentGroup(state).members[index][0];

void main() {
  test('memberInitial', () {
    expect(app.memberInitial(sample(), 1), 'B');
  });
}
