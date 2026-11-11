// lineIcon: Cart line index item icon.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String lineIcon(State state, int index) {
  final String id = state.cart[index].itemId;
  var out = '';
  for (final MenuItem m in state.menu) {
    if (m.id == id) out = m.icon;
  }
  return out;
}

void main() {
  test('index 1', () {
    expect(app.lineIcon(sample(), 1), 'restaurant');
  });
}
