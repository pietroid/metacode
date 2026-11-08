// startOver: Starts the onboarding again, keeping the answers as they were.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> startOver(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(stage: Stage.budget));
}

void main() {
  test('startOver', () async {
    expect((await app.startOver(sample(goal: Goal.weightLoss, program: 8))).stage, Stage.budget);
  });
}
