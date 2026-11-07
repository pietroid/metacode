import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('food servings add, remove and clear', () async {
    var s = await app.addFood(sample(), 1);
    s = await app.addFood(s, 1);
    expect(s.foods[1].count, 2);
    s = await app.removeFood(s, 1);
    expect(s.foods[1].count, 1);
    expect((await app.removeFood(sample(), 0)).foods[0].count, 0);
    expect((await app.clearFoods(s)).foods[1].count, 0);
  });
}
