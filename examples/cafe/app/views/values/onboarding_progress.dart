// onboardingProgress: (onboardingStep + 1) / 3.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

num onboardingProgress(State state) => (state.onboardingStep + 1) / 3;

void main() {
  test('step 0', () {
    expect(app.onboardingProgress(sample()), closeTo(1 / 3, 0.001));
  });
}
