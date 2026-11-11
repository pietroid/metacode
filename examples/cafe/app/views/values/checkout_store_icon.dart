// checkoutStoreIcon: radioUnchecked when index is checkoutStore, else ink3.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String checkoutStoreIcon(State state, int index) {
  if (state.checkoutStore == index) return 'radioUnchecked';
  return 'ink3';
}

void main() {
  test('selected', () {
    expect(app.checkoutStoreIcon(sample(), 0), 'radioUnchecked');
  });
  test('other', () {
    expect(app.checkoutStoreIcon(sample(), 2), 'ink3');
  });
}
