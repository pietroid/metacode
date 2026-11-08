// exampleHasPhoto: Whether the current example shows a photo above it in the
// phone (music and plants; food and work show only their app).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool exampleHasPhoto(State state) {
  final i = state.exampleIndex.round();
  return i == 1 || i == 3;
}

void main() {
  test('exampleHasPhoto', () {
    expect(app.exampleHasPhoto(sample(exampleIndex: 1)), isTrue);
    expect(app.exampleHasPhoto(sample(exampleIndex: 2)), isFalse);
  });
}
