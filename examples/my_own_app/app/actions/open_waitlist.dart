// openWaitlist: Opens the waitlist dialog.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// Opens the waitlist dialog.
Future<void> openWaitlist(State state, Core core) async {
  core.navigator.push(Routes.waitlist);
}

void main() {
  test('openWaitlist pushes the dialog', () async {
    await app.openWaitlist(sample());
    expect(app.navigation, ['push waitlist']);
  });
}
