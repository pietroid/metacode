// rewardsList: the rewards.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Reward> rewardsList(State state) => state.rewards;

void main() {
  test('rewardsList', () {
    expect(app.rewardsList(sample()).length, 4);
  });
  test('rewardsList empty', () {
    expect(app.rewardsList(sample({'rewards': []})).length, 0);
  });
}
