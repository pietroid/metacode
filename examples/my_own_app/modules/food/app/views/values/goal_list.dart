// goalList: The goal cards on the goal step.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<GoalOption> goalList(State state) => state.goalOptions;

void main() {
  test('goalList', () async {
    expect(app.goalList(sample()).length, 3);
  });
}
