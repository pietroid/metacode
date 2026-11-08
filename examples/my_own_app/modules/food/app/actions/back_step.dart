// backStep: Moves the onboarding one step back.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> backStep(State state, void Function(StateDelta) emit) async {
  if (state.stage == Stage.goal) emit(StateDelta(stage: Stage.prefs));
  if (state.stage == Stage.prefs) emit(StateDelta(stage: Stage.budget));
}

void main() {
  test('backStep', () async {
    expect((await app.backStep(sample(stage: Stage.goal))).stage, Stage.prefs);
  });
}
