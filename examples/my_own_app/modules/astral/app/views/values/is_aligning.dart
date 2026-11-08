// isAligning: Whether the stars are still aligning (stage 1): the spinner and "Aligning the stars…" show over the wheel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool isAligning(State state) => state.readingStage == 1;

void main() {
  test('isAligning', () {
    expect(app.isAligning(sample(readingStage: 1)), true);
    expect(app.isAligning(sample(readingStage: 2)), false);
  });
}
