// onboardingBody: welcomeBody, storeStepBody or rewardsStepBody by onboardingStep.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String onboardingBody(State state, Labels labels) {
  if (state.onboardingStep == 1) return labels.storeStepBody;
  if (state.onboardingStep == 2) return labels.rewardsStepBody;
  return labels.welcomeBody;
}

void main() {
  test('step 2 is rewards body', () {
    expect(app.onboardingBody(sample({'onboardingStep': 2})), 'Earn 1 star for every dollar. 150 stars is a free drink.');
  });
}
