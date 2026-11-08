// nextStep: Moves the onboarding one step forward (budget, prefs, goal).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> nextStep(State state, void Function(StateDelta) emit) async {
  if (state.stage == Stage.budget) emit(StateDelta(stage: Stage.prefs));
  if (state.stage == Stage.prefs) emit(StateDelta(stage: Stage.goal));
}

void main() {
  test('nextStep', () async {
    expect((await app.nextStep(sample())).stage, Stage.prefs);
    expect((await app.nextStep(sample(stage: Stage.prefs))).stage, Stage.goal);
  });
}
