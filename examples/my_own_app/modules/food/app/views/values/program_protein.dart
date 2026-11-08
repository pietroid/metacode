// programProtein: The picked program's daily protein target.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/has_program.dart';

String programProtein(State state) {
  if (!hasProgram(state)) return '';
  return '${state.programs[state.program.toInt()].protein} g';
}

void main() {
  test('programProtein', () async {
    expect(app.programProtein(sample(goal: Goal.weightLoss, program: 8)), '120 g');
  });
}
