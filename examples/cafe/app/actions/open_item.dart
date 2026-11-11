// openItem: maps the visible item index (category, or name search across all
// when search is set) to its menu index, selects it, resets the draft and
// pushes the item page.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openItem(State state, void Function(StateDelta) emit, Core core, int index) async {
  final String q = state.search.trim().toLowerCase();
  var count = 0;
  var found = -1;
  for (var i = 0; i < state.menu.length; i++) {
    final MenuItem it = state.menu[i];
    var ok = false;
    if (q.isEmpty) {
      ok = it.category == state.category;
    } else {
      ok = it.name.toLowerCase().contains(q);
    }
    if (ok) {
      if (count == index && found < 0) found = i;
      count++;
    }
  }
  if (found < 0) return;
  final bool custom = state.menu[found].customizable;
  final Milk milk = custom ? Milk.whole : Milk.none;
  emit(StateDelta(
    selectedItem: found,
    draftSize: DrinkSize.medium,
    draftMilk: milk,
    draftShots: 0,
    draftQuantity: 1,
  ));
  core.navigator.push(Routes.item);
}

void main() {
  test('openItem maps by category', () async {
    final s = await app.openItem(sample({'category': 'tea'}), 1);
    expect(s.selectedItem, 5);
    expect(s.draftMilk, Milk.whole);
    expect(app.navigation, ['push item']);
  });
  test('openItem maps by search', () async {
    final s = await app.openItem(sample({'search': 'muffin'}), 0);
    expect(s.selectedItem, 11);
    expect(s.draftMilk, Milk.none);
  });
}
