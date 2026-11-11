// onboardingTitle: welcomeTitle, storeStepTitle or rewardsStepTitle by
// onboardingStep.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String onboardingTitle(State state, Labels labels) {
  if (state.onboardingStep == 1) return labels.storeStepTitle;
  if (state.onboardingStep == 2) return labels.rewardsStepTitle;
  return labels.welcomeTitle;
}

void main() {
  test('onboardingTitle', () {
    expect(app.onboardingTitle(sample()), 'Welcome to Ember & Oak');
    expect(app.onboardingTitle(sample({'onboardingStep': 2})), 'Turn on rewards');
  });
}
