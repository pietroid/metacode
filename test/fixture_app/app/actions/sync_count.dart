// syncCount: Taps the counter module from code, then copies its tap count
// (a value of the module) into count.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> syncCount(
    State state, void Function(StateDelta) emit, Core core) async {
  await core.modules.counter.tap();
  final taps = await core.modules.counter.tapCount();
  emit(StateDelta(count: taps));
}

void main() {
  test('syncCount taps the counter and copies its count', () async {
    app.moduleValues['counter.tapCount'] = 3;
    final state = await app.syncCount(sample());
    expect(app.moduleCalls, ['counter.tap']);
    expect(state.count, 3);
  });
}
