// groupName: Group index's name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String groupName(State state, int index) => state.groups[index].name;

void main() {
  test('groupName', () {
    expect(app.groupName(sample(), 1), 'Flat 3B');
  });
}
