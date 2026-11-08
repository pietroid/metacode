// programKcal: The picked program's daily kcal target.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/group_digits.dart';
import 'shared/has_program.dart';

String programKcal(State state, Labels labels) {
  if (!hasProgram(state)) return '';
  return groupDigits(state.programs[state.program.toInt()].kcal, labels.thousandsSep);
}

void main() {
  test('programKcal', () async {
    expect(app.programKcal(sample(goal: Goal.weightLoss, program: 8)), '1,600');
  });
}
