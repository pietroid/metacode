// orderLineDetails: Selected order line index options.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String orderLineDetails(State state, Labels labels, int index) {
  final CartLine l = state.orders[state.selectedOrder.toInt()].lines[index];
  var custom = false;
  for (final MenuItem m in state.menu) {
    if (m.id == l.itemId && m.customizable) custom = true;
  }
  if (!custom) return '';
  final List<String> parts = [];
  if (l.size == DrinkSize.small) parts.add(labels.sizeSmall);
  if (l.size == DrinkSize.medium) parts.add(labels.sizeMedium);
  if (l.size == DrinkSize.large) parts.add(labels.sizeLarge);
  if (l.milk == Milk.whole) parts.add(labels.milkWhole);
  if (l.milk == Milk.oat) parts.add(labels.milkOat);
  if (l.milk == Milk.almond) parts.add(labels.milkAlmond);
  final int n = l.shots.toInt();
  if (n == 1) parts.add('$n ${labels.shot}');
  if (n > 1) parts.add('$n ${labels.shots}');
  return parts.join(' · ');
}

void main() {
  test('index 0', () {
    expect(app.orderLineDetails(sample(), 0), 'Medium · Whole');
  });
  test('pastry', () {
    expect(app.orderLineDetails(sample(), 1), '');
  });
}
