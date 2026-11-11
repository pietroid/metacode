// rewardAvailable: whether the stars cover reward index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool rewardAvailable(State state, int index) {
  if (index < 0 || index >= state.rewards.length) return false;
  return state.stars >= state.rewards[index].stars;
}

void main() {
  test('rewardAvailable', () {
    expect(app.rewardAvailable(sample(), 1), true);
    expect(app.rewardAvailable(sample(), 2), false);
  });
}
