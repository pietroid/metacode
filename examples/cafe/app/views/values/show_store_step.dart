// showStoreStep: onboardingStep is 1.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool showStoreStep(State state) => state.onboardingStep == 1;

void main() {
  test('step 1', () {
    expect(app.showStoreStep(sample({'onboardingStep': 1})), true);
  });
}
