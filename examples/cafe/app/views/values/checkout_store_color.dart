// checkoutStoreColor: ink3 when index is checkoutStore, else ink3.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String checkoutStoreColor(State state, int index) {
  if (state.checkoutStore == index) return 'ink3';
  return 'ink3';
}

void main() {
  test('selected', () {
    expect(app.checkoutStoreColor(sample(), 0), 'ink3');
  });
  test('other', () {
    expect(app.checkoutStoreColor(sample(), 2), 'ink3');
  });
}
