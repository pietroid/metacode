// selectCategory: sets category to the category at index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectCategory(State state, void Function(StateDelta) emit, int index) async {
  const cats = <Category>[Category.coffee, Category.tea, Category.coldDrinks, Category.bakery];
  if (index < 0 || index >= cats.length) return;
  emit(StateDelta(category: cats[index]));
}

void main() {
  test('selectCategory', () async {
    final s = await app.selectCategory(sample(), 3);
    expect(s.category, Category.bakery);
  });
}
