// ideaIsMeals: Whether the current idea is the meal-planner prompt.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsMeals(State state) => state.idea == 'Plan meals for the week';

void main() {
  test('ideaIsMeals', () {
    expect(app.ideaIsMeals(sample(idea: 'Plan meals for the week')), isTrue);
  });
}
