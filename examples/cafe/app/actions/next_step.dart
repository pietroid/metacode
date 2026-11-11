// nextStep: advances onboardingStep; on the last step (2) finishes: onboarded
// true and checkoutStore = favoriteStore.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> nextStep(State state, void Function(StateDelta) emit) async {
  if (state.onboardingStep.toInt() >= 2) {
    emit(StateDelta(onboarded: true, checkoutStore: state.favoriteStore));
  } else {
    emit(StateDelta(onboardingStep: state.onboardingStep + 1));
  }
}

void main() {
  test('nextStep advances', () async {
    final s = await app.nextStep(sample());
    expect(s.onboardingStep, 1);
    expect(s.onboarded, false);
  });
  test('nextStep finishes on the last step', () async {
    final s = await app.nextStep(sample({'onboardingStep': 2, 'favoriteStore': 2}));
    expect(s.onboarded, true);
    expect(s.checkoutStore, 2);
  });
}
