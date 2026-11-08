// programCarbs: The picked program's daily carbs target.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/has_program.dart';

String programCarbs(State state) {
  if (!hasProgram(state)) return '';
  return '${state.programs[state.program.toInt()].carbs} g';
}

void main() {
  test('programCarbs', () async {
    expect(app.programCarbs(sample(goal: Goal.weightLoss, program: 8)), '150 g');
  });
}
