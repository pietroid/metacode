// openWaitlist: Opens the waitlist bottom sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

/// Opens the waitlist sheet.
Future<void> openWaitlist(State state, Core core) async {
  core.navigator.push(Routes.waitlist);
}

void main() {
  test('openWaitlist pushes the sheet', () async {
    await app.openWaitlist(sample());
    expect(app.navigation, ['push waitlist']);
  });
}
