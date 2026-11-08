// openPrefs: Onboarding step 2: opens the prefs page over the budget step.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openPrefs(State state, Core core) async {
  core.navigator.push(Routes.prefs);
}

void main() {
  test('openPrefs', () async {
    await app.openPrefs(sample());
    expect(app.navigation, ['push prefs']);
  });
}
