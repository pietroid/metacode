// sizeSelected: Whether size index is the draft size.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool sizeSelected(State state, int index) {
  if (index == 0) return state.draftSize == DrinkSize.small;
  if (index == 1) return state.draftSize == DrinkSize.medium;
  return state.draftSize == DrinkSize.large;
}

void main() {
  test('initial', () {
    expect(app.sizeSelected(sample(), 1), true);
    expect(app.sizeSelected(sample(), 0), false);
  });
}
