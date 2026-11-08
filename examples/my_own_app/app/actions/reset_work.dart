// resetWork: Starts the work example over: its state back to its first launch, its open screens closed.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> resetWork(State state, Core core) async {
  await core.modules.reset('work');
}

void main() {
  test('resetWork resets the work module', () async {
    await app.resetWork(sample());
    expect(app.modulesReset, ['work']);
  });
}
