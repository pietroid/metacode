// insightReveal: How much of each insight shows: typed out from stage 4, cleared at once when the date changes.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 2200, curve: 'linear', reverseMs: 0)
double insightReveal(State state) => state.readingStage >= 4 ? 1.0 : 0.0;

void main() {
  test('insightReveal follows the reading stage', () {
    expect(app.insightReveal(sample(readingStage: 0)), 0.0);
    expect(app.insightReveal(sample(readingStage: 5)), 1.0);
  });
}
