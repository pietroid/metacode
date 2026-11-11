// lineName: Cart line index item name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String lineName(State state, int index) {
  final String id = state.cart[index].itemId;
  var out = '';
  for (final MenuItem m in state.menu) {
    if (m.id == id) out = m.name;
  }
  return out;
}

void main() {
  test('index 0', () {
    expect(app.lineName(sample(), 0), 'Caffè Latte');
  });
}
