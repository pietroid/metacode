// rewardsEnabled: rewardsOn.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool rewardsEnabled(State state) => state.rewardsOn;

void main() {
  test('initial', () {
    expect(app.rewardsEnabled(sample()), false);
  });
}
