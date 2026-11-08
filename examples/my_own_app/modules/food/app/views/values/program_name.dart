// programName: The picked program's name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/has_program.dart';
import 'shared/pick.dart';

String programName(State state, Labels labels) {
  if (!hasProgram(state)) return '';
  final p = state.programs[state.program.toInt()];
  return pick(labels, p.name, p.namePt);
}

void main() {
  test('programName', () async {
    expect(app.programName(sample(goal: Goal.weightLoss, program: 8)), 'Lighter Days');
  });
}
