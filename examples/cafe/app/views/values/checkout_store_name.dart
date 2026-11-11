// checkoutStoreName: Name of the checkout store.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String checkoutStoreName(State state) {
  return state.stores[state.checkoutStore.toInt()].name;
}

void main() {
  test('initial', () {
    expect(app.checkoutStoreName(sample()), 'Downtown');
  });
}
