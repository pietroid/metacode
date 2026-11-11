// filterCategoryOptions: allCategories, food, travel, home, other labels.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<String> filterCategoryOptions(State state, Labels labels) =>
    [labels.allCategories, labels.food, labels.travel, labels.home, labels.other];

void main() {
  test('filterCategoryOptions', () {
    final o = app.filterCategoryOptions(sample());
    expect(o.length, 5);
    expect(o.first, 'All');
  });
}
