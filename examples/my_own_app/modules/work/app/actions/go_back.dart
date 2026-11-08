// goBack: Closes the section page, back to Today.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> goBack(State state, Core core) async {
  await core.navigator.pop();
}

void main() {
  test('goBack', () async {
    await app.goBack(sample());
    expect(app.navigation, ['pop']);
  });
}
