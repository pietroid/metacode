// milkSelected: Whether milk index is the draft milk.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool milkSelected(State state, int index) {
  if (index == 0) return state.draftMilk == Milk.whole;
  if (index == 1) return state.draftMilk == Milk.oat;
  if (index == 2) return state.draftMilk == Milk.almond;
  return state.draftMilk == Milk.none;
}

void main() {
  test('initial', () {
    expect(app.milkSelected(sample(), 0), true);
    expect(app.milkSelected(sample(), 1), false);
  });
}
