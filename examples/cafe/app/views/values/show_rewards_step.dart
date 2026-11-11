// showRewardsStep: onboardingStep is 2.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool showRewardsStep(State state) => state.onboardingStep == 2;

void main() {
  test('step 2', () {
    expect(app.showRewardsStep(sample({'onboardingStep': 2})), true);
  });
}
