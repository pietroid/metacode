// filterCategoryOptionText: Option index of filterCategoryOptions.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String filterCategoryOptionText(State state, Labels labels, int index) {
  final List<String> o = [labels.allCategories, labels.food, labels.travel, labels.home, labels.other];
  return o[index];
}

void main() {
  test('filterCategoryOptionText', () {
    expect(app.filterCategoryOptionText(sample(), 2), 'Travel');
  });
}
