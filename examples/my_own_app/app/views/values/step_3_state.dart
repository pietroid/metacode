// step3State: The visual state of the third build-step indicator.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String _step3StateStepState(State state, int step) {
  if (state.buildStep > step) return 'done';
  if (state.buildStep == step) return 'doing';
  return 'todo';
}

String step3State(State state) => _step3StateStepState(state, 3);

void main() {
  test('step3State', () {
    expect(app.step3State(sample(buildStep: 2)), 'todo');
  });
}
