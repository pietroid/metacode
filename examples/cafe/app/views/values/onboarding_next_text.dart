// onboardingNextText: next label, or getStarted on step 2.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String onboardingNextText(State state, Labels labels) {
  if (state.onboardingStep == 2) return labels.getStarted;
  return labels.next;
}

void main() {
  test('step 2', () {
    expect(app.onboardingNextText(sample({'onboardingStep': 2})), 'Get started');
  });
}
