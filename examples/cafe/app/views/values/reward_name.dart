// rewardName: name of reward index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String rewardName(State state, int index) {
  if (index < 0 || index >= state.rewards.length) return '';
  return state.rewards[index].name;
}

void main() {
  test('rewardName', () {
    expect(app.rewardName(sample(), 2), 'Free drink');
  });
  test('rewardName out of range', () {
    expect(app.rewardName(sample(), 9), '');
  });
}
