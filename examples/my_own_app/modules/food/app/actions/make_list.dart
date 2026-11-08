// makeList: Builds the shopping list from the accepted recipes (the same ingredient merges into one line) and opens it in place of the swipe.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> makeList(State state, void Function(StateDelta) emit, Core core) async {
  final items = <Item>[];
  for (final p in state.picked) {
    for (final g in state.recipes[p.toInt()].ingredients) {
      var found = false;
      for (final it in items) {
        if (it.name == g.name) {
          it.count = it.count + 1;
          it.price = it.price + g.price;
          it.kcal = it.kcal + g.kcal;
          found = true;
        }
      }
      if (!found) {
        items.add(Item(name: g.name, namePt: g.namePt, qty: g.qty, price: g.price, kcal: g.kcal, count: 1, checked: false, bought: false));
      }
    }
  }
  emit(StateDelta(shopping: items));
  await core.navigator.pop();
  // Let the pop land before pushing, or the navigator drops it.
  await Future.delayed(Duration(milliseconds: 1));
  core.navigator.push(Routes.shopping);
}

void main() {
  test('makeList', () async {
    final s = await app.makeList(sample(goal: Goal.weightLoss, program: 8).copyWith(picked: [12, 3]));
    expect(app.navigation, ['pop', 'push shopping']);
    expect(s.shopping.length, 9); // olive oil appears in both
    final oil = s.shopping.firstWhere((Item i) => i.name == 'Olive oil');
    expect(oil.count, 2);
    expect(oil.price, 2);
  });
}
