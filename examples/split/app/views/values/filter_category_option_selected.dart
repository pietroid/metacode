// filterCategoryOptionSelected: Index 0 when filterCategory is empty, else the category at index - 1 equals filterCategory.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool filterCategoryOptionSelected(State state, int index) {
  if (index == 0) return state.filterCategory.isEmpty;
  final List<String> names = ['food', 'travel', 'home', 'other'];
  return names[index - 1] == state.filterCategory;
}

void main() {
  test('filterCategoryOptionSelected', () {
    expect(app.filterCategoryOptionSelected(sample(), 0), true);
    expect(app.filterCategoryOptionSelected(sample({'filterCategory': 'travel'}), 2), true);
    expect(app.filterCategoryOptionSelected(sample({'filterCategory': 'travel'}), 0), false);
  });
}
