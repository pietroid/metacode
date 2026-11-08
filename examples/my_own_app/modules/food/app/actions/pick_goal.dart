// pickGoal: Picks the goal of the tapped goal card.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> pickGoal(State state, void Function(StateDelta) emit, int index) async {
  emit(StateDelta(goal: state.goalOptions[index].goal));
}

void main() {
  test('pickGoal', () async {
    expect((await app.pickGoal(sample(), 1)).goal, Goal.hypertrophy);
  });
}
