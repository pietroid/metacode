// showOnboarding: true while onboarded is false.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool showOnboarding(State state) => !state.onboarded;

void main() {
  test('showOnboarding', () {
    expect(app.showOnboarding(sample()), true);
    expect(app.showOnboarding(sample({'onboarded': true})), false);
  });
}
