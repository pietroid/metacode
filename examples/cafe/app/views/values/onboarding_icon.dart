// onboardingIcon: step icon - 0 sparkle, 1 location, 2 star.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String onboardingIcon(State state) {
  if (state.onboardingStep == 1) return 'location';
  if (state.onboardingStep == 2) return 'star';
  return 'sparkle';
}

void main() {
  test('onboardingIcon', () {
    expect(app.onboardingIcon(sample({'onboardingStep': 1})), 'location');
    expect(app.onboardingIcon(sample()), 'sparkle');
  });
}
