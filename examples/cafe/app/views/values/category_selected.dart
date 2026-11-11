// categorySelected: Category index is the selected category.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/category_at.dart';

bool categorySelected(State state, int index) => state.category == categoryAt(index);

void main() {
  test('index 0', () {
    expect(app.categorySelected(sample(), 0), true);
  });
  test('index 1', () {
    expect(app.categorySelected(sample(), 1), false);
  });
}
