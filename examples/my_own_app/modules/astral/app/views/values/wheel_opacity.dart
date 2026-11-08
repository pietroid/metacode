// wheelOpacity: The chart wheel: fades in slowly from stage 2, gone at once when the date changes.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 1400, curve: 'easeInOutCubic', reverseMs: 0)
double wheelOpacity(State state) => state.readingStage >= 2 ? 1.0 : 0.0;

void main() {
  test('wheelOpacity follows the reading stage', () {
    expect(app.wheelOpacity(sample(readingStage: 0)), 0.0);
    expect(app.wheelOpacity(sample(readingStage: 5)), 1.0);
  });
}
