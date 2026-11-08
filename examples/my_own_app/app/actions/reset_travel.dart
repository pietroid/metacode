// resetTravel: Starts the travel example over: its state back to its first launch, its open screens closed.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> resetTravel(State state, Core core) async {
  await core.modules.reset('travel');
}

void main() {
  test('resetTravel resets the travel module', () async {
    await app.resetTravel(sample());
    expect(app.modulesReset, ['travel']);
  });
}
