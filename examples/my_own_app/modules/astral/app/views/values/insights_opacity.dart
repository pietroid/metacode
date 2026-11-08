// insightsOpacity: The insights card: fades in from stage 4.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 600, curve: 'easeOut', reverseMs: 0)
double insightsOpacity(State state) => state.readingStage >= 4 ? 1.0 : 0.0;

void main() {
  test('insightsOpacity follows the reading stage', () {
    expect(app.insightsOpacity(sample(readingStage: 0)), 0.0);
    expect(app.insightsOpacity(sample(readingStage: 5)), 1.0);
  });
}
