// step2State returns the visual state of the second build-step indicator.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String _step2StateStepState(State state, int step) {
  if (state.buildStep > step) return 'done';
  if (state.buildStep == step) return 'doing';
  return 'todo';
}

String step2State(State state) => _step2StateStepState(state, 2);

void main() {
  test('step2State', () {
    expect(app.step2State(sample(buildStep: 2)), 'doing');
  });
}
