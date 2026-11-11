// historySubtitle: date, store and item count of order index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String historySubtitle(State state, Labels labels, int index) {
  if (index < 0 || index >= state.orders.length) return '';
  final Order o = state.orders[index];
  int count = 0;
  for (final CartLine l in o.lines) {
    count += l.quantity.toInt();
  }
  final int s = o.store.toInt();
  final String store = (s >= 0 && s < state.stores.length) ? state.stores[s].name : '';
  final String word = count == 1 ? labels.item : labels.items;
  return '${o.placedAt} · $store · $count $word';
}

void main() {
  test('historySubtitle', () {
    expect(app.historySubtitle(sample(), 0), 'Nov 10, 8:42 AM · Downtown · 2 items');
  });
  test('historySubtitle out of range', () {
    expect(app.historySubtitle(sample(), 5), '');
  });
}
