// restartOnboarding: sets onboarded false and onboardingStep 0.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> restartOnboarding(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(onboarded: false, onboardingStep: 0));
}

void main() {
  test('restartOnboarding', () async {
    final s = await app.restartOnboarding(sample({'onboarded': true, 'onboardingStep': 2}));
    expect(s.onboarded, false);
    expect(s.onboardingStep, 0);
  });
}
