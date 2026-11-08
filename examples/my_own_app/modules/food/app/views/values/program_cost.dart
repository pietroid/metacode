// programCost: The picked program's estimated monthly cost against the budget.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/has_program.dart';
import 'shared/money.dart';

String programCost(State state, Labels labels) {
  if (!hasProgram(state)) return '';
  final cost = state.programs[state.program.toInt()].monthlyCost;
  final fit = cost <= state.budget ? labels.fitsBudget : labels.overBudget;
  return '${labels.about} ${money(cost, labels)}${labels.perMonth}, $fit';
}

void main() {
  test('programCost', () async {
    expect(app.programCost(sample(goal: Goal.weightLoss, program: 8)), r'About $280/mo, fits your budget');
  });
}
