// openStorePicker: pushes the storePicker dialog.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openStorePicker(State state, Core core) async {
  core.navigator.push(Routes.storePicker);
}

void main() {
  test('openStorePicker', () async {
    await app.openStorePicker(sample());
    expect(app.navigation, ['push storePicker']);
  });
}
