// visibleItems: items in the category; with a search, items whose name contains it across all categories.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<MenuItem> visibleItems(State state) {
  final String q = state.search.trim().toLowerCase();
  if (q.isNotEmpty) {
    return state.menu
        .where((MenuItem m) => m.name.toLowerCase().contains(q))
        .toList();
  }
  return state.menu.where((MenuItem m) => m.category == state.category).toList();
}

void main() {
  test('initial 4 coffees', () {
    expect(app.visibleItems(sample()).length, 4);
  });
  test('search latte', () {
    expect(app.visibleItems(sample({'search': 'latte'})).length, 4);
  });
}
