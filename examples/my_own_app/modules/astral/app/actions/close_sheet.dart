// closeSheet: Closes the sheet on top (the booking or a course).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> closeSheet(State state, Core core) async {
  await core.navigator.pop();
}

void main() {
  test('closeSheet', () async {
    await app.closeSheet(sample());
    expect(app.navigation, ['pop']);
  });
}
