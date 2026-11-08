// ideaIsMeals: Whether the studio idea is the meals chip.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsMeals(State state) => state.appKind == AppKind.meals;

void main() {
  test('ideaIsMeals', () {
    expect(app.ideaIsMeals(sample(appKind: AppKind.meals)), isTrue);
    expect(app.ideaIsMeals(sample()), isFalse);
  });
}
