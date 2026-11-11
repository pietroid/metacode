// groupMembersText: Group index's members joined with ', '.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String groupMembersText(State state, int index) => state.groups[index].members.join(', ');

void main() {
  test('groupMembersText', () {
    expect(app.groupMembersText(sample(), 1), 'Ana, Eli, Fran');
  });
}
