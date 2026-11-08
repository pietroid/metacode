// openGoal: Onboarding step 3: opens the goal page over the prefs step.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openGoal(State state, Core core) async {
  core.navigator.push(Routes.goal);
}

void main() {
  test('openGoal', () async {
    await app.openGoal(sample());
    expect(app.navigation, ['push goal']);
  });
}
