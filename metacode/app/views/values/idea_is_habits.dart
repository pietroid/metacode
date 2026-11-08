// ideaIsHabits: Whether the current idea is the habit-tracker prompt.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsHabits(State state) => state.idea == 'Track my daily habits';

void main() {
  test('ideaIsHabits', () {
    expect(app.ideaIsHabits(sample(idea: 'Track my daily habits')), isTrue);
  });
}
