// placementsOpacity: The placements and elements: fade in from stage 3, after the wheel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 800, curve: 'easeOut', reverseMs: 0)
double placementsOpacity(State state) => state.readingStage >= 3 ? 1.0 : 0.0;

void main() {
  test('placementsOpacity follows the reading stage', () {
    expect(app.placementsOpacity(sample(readingStage: 0)), 0.0);
    expect(app.placementsOpacity(sample(readingStage: 5)), 1.0);
  });
}
