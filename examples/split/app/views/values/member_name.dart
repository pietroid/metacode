// memberName: currentMembers[index].

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import '../../models/sample.dart';

String memberName(State state, int index) => currentGroup(state).members[index];

void main() {
  test('memberName', () {
    expect(app.memberName(sample(), 3), 'Dev');
  });
}
