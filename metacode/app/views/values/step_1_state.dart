// step1State returns the visual state of the first build-step indicator.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String _step1StateStepState(State state, int step) {
  if (state.buildStep > step) return 'done';
  if (state.buildStep == step) return 'doing';
  return 'todo';
}

String step1State(State state) => _step1StateStepState(state, 1);

void main() {
  test('step1State', () {
    expect(app.step1State(sample(buildStep: 2)), 'done');
  });
}
