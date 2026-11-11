// rewardIcon: icon of reward index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String rewardIcon(State state, int index) {
  if (index < 0 || index >= state.rewards.length) return 'gift';
  return state.rewards[index].icon;
}

void main() {
  test('rewardIcon', () {
    expect(app.rewardIcon(sample(), 2), 'gift');
  });
  test('rewardIcon first', () {
    expect(app.rewardIcon(sample(), 0), 'plusCircle');
  });
}
