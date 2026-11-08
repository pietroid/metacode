// consultOpacity: The consult-an-astrologer card: fades in last (stage 5).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 900, curve: 'easeOut', reverseMs: 0)
double consultOpacity(State state) => state.readingStage >= 5 ? 1.0 : 0.0;

void main() {
  test('consultOpacity follows the reading stage', () {
    expect(app.consultOpacity(sample(readingStage: 0)), 0.0);
    expect(app.consultOpacity(sample(readingStage: 5)), 1.0);
  });
}
