// goHome: Leaves an example's live page, back to the landing page.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> goHome(State state, Core core) async {
  await core.navigator.pop();
}

void main() {
  test('goHome pops the live page', () async {
    await app.goHome(sample());
    expect(app.navigation, ['pop']);
  });
}
