// lineColor: Cart line index item color.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String lineColor(State state, int index) {
  final String id = state.cart[index].itemId;
  var out = '';
  for (final MenuItem m in state.menu) {
    if (m.id == id) out = m.color;
  }
  return out;
}

void main() {
  test('index 1', () {
    expect(app.lineColor(sample(), 1), '#E0A85A');
  });
}
