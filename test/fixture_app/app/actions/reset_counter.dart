// resetCounter: Starts the counter module over (core.modules.reset).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> resetCounter(State state, Core core) async {
  await core.modules.reset('counter');
}

void main() {
  test('resetCounter resets the counter module', () async {
    await app.resetCounter(sample());
    expect(app.modulesReset, ['counter']);
  });
}
