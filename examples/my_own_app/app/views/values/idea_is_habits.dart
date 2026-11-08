// ideaIsHabits: Whether the studio idea is the habits chip.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsHabits(State state) => state.appKind == AppKind.habits;

void main() {
  test('ideaIsHabits', () {
    expect(app.ideaIsHabits(sample(appKind: AppKind.habits)), isTrue);
    expect(app.ideaIsHabits(sample()), isFalse);
  });
}
