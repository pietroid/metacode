// setRewards: sets rewardsOn to the value.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setRewards(State state, void Function(StateDelta) emit, bool value) async {
  emit(StateDelta(rewardsOn: value));
}

void main() {
  test('setRewards', () async {
    final s = await app.setRewards(sample(), true);
    expect(s.rewardsOn, true);
  });
}
