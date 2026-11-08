// ideaIsBills: Whether the current idea is the bill-splitter prompt.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsBills(State state) => state.idea == 'Split bills with roommates';

void main() {
  test('ideaIsBills', () {
    expect(app.ideaIsBills(sample(idea: 'Split bills with roommates')), isTrue);
  });
}
