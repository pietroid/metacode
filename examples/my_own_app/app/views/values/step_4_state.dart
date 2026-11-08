// step4State: The visual state of the fourth build-step indicator.
import '../../../.generated/state.dart';

String _step4StateStepState(State state, int step) {
  if (state.buildStep > step) return 'done';
  if (state.buildStep == step) return 'doing';
  return 'todo';
}

String step4State(State state) => _step4StateStepState(state, 4);
