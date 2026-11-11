// categoryList: all categories.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Category> categoryList(State state) {
  return [Category.coffee, Category.tea, Category.coldDrinks, Category.bakery];
}

void main() {
  test('4 categories', () {
    expect(app.categoryList(sample()).length, 4);
  });
}
