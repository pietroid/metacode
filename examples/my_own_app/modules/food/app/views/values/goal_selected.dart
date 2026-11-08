// goalSelected: Whether a goal card is the picked goal.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool goalSelected(State state, int index) => state.goalOptions[index].goal == state.goal;

void main() {
  test('goalSelected', () async {
    expect(app.goalSelected(sample(goal: Goal.hypertrophy), 1), true);
    expect(app.goalSelected(sample(), 1), false);
  });
}
