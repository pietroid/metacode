// finishShopping: Shopping done: the whole list counts as bought (checked too), so its cost and kcal fill the budget and calorie meters, then back to the plan.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> finishShopping(State state, void Function(StateDelta) emit, Core core) async {
  for (final i in state.shopping) {
    i.checked = true;
    i.bought = true;
  }
  emit(StateDelta(shopping: state.shopping));
  await core.navigator.pop();
}

void main() {
  test('finishShopping', () async {
    final s = await app.finishShopping(sample(stage: Stage.plan).copyWith(shopping: [Item(name: 'A', namePt: 'A', qty: '1', price: 30, kcal: 600, count: 1, checked: true, bought: false), Item(name: 'B', namePt: 'B', qty: '1', price: 10, kcal: 200, count: 1, checked: false, bought: false)]));
    expect(app.navigation, ['pop']);
    expect(s.shopping[1].bought, true);
    expect(app.budgetSpent(s), r'$40.00 of $300');
    expect(app.kcalStocked(s), '800 of 800 kcal');
  });
}
