// programFits: Whether the picked program's monthly cost fits the budget.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/has_program.dart';

bool programFits(State state) {
  if (!hasProgram(state)) return true;
  return state.programs[state.program.toInt()].monthlyCost <= state.budget;
}

void main() {
  test('programFits', () async {
    expect(app.programFits(sample(goal: Goal.weightLoss, program: 8)), true);
    expect(app.programFits(sample(goal: Goal.weightLoss, program: 8, budget: 200)), false);
  });
}
