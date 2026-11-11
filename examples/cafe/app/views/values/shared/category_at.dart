// categoryAt: the Category for an index (coffee, tea, coldDrinks, bakery).

import '../../../../.generated/state.dart';
Category categoryAt(int index) {
  if (index == 0) return Category.coffee;
  if (index == 1) return Category.tea;
  if (index == 2) return Category.coldDrinks;
  return Category.bakery;
}
