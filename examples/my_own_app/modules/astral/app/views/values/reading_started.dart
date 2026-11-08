// readingStarted: Whether the map reading has started (the map section shows).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool readingStarted(State state) => state.readingStage >= 1;

void main() {
  test('readingStarted', () {
    expect(app.readingStarted(sample()), false);
    expect(app.readingStarted(sample(readingStage: 1)), true);
  });
}
