// hasGoal: Whether a goal is picked, so the program can be built.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool hasGoal(State state) => state.goal != Goal.none;

void main() {
  test('hasGoal', () async {
    expect(app.hasGoal(sample()), false);
    expect(app.hasGoal(sample(goal: Goal.lowCarb)), true);
  });
}
