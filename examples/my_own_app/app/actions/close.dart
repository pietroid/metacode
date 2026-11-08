// close: Closes the currently open route (dialog or page).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// Closes the dialog on top.
Future<void> close(State state, Core core) async {
  await core.navigator.pop();
}

void main() {
  test('close pops the dialog on top', () async {
    await app.close(sample());
    expect(app.navigation, ['pop']);
  });
}
