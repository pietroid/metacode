// resetFood: Starts the food example over: its state back to its first launch, its open screens closed.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> resetFood(State state, Core core) async {
  await core.modules.reset('food');
}

void main() {
  test('resetFood resets the food module', () async {
    await app.resetFood(sample());
    expect(app.modulesReset, ['food']);
  });
}
