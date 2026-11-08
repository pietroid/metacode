// programTagline: The picked program's one-line description.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/has_program.dart';
import 'shared/pick.dart';

String programTagline(State state, Labels labels) {
  if (!hasProgram(state)) return '';
  final p = state.programs[state.program.toInt()];
  return pick(labels, p.tagline, p.taglinePt);
}

void main() {
  test('programTagline', () async {
    expect(app.programTagline(sample(goal: Goal.weightLoss, program: 8)), contains('deficit'));
  });
}
