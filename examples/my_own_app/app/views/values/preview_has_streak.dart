// previewHasStreak: Whether the studio preview app shows the weekly streak card.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool previewHasStreak(State state) => state.appStreak;

void main() {
  test('previewHasStreak', () {
    expect(app.previewHasStreak(sample(appStreak: true)), isTrue);
  });
}
