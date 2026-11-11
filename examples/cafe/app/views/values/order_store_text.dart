// orderStoreText: name and address of the selected order's store.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String orderStoreText(State state) {
  final int o = state.selectedOrder.toInt();
  if (o < 0 || o >= state.orders.length) return '';
  final int s = state.orders[o].store.toInt();
  if (s < 0 || s >= state.stores.length) return '';
  return '${state.stores[s].name} · ${state.stores[s].address}';
}

void main() {
  test('orderStoreText', () {
    expect(app.orderStoreText(sample()), 'Downtown · 120 Market St');
  });
  test('orderStoreText out of range', () {
    expect(app.orderStoreText(sample({'selectedOrder': 9})), '');
  });
}
