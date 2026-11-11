// categoryLabel: catCoffee, catTea, catColdDrinks, catBakery for category index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String categoryLabel(State state, Labels labels, int index) {
  if (index == 0) return labels.catCoffee;
  if (index == 1) return labels.catTea;
  if (index == 2) return labels.catColdDrinks;
  return labels.catBakery;
}

void main() {
  test('index 2', () {
    expect(app.categoryLabel(sample(), 2), 'Cold drinks');
  });
}
