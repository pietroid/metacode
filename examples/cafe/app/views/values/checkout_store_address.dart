// checkoutStoreAddress: Checkout store 'address · distance'.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String checkoutStoreAddress(State state) {
  final Store s = state.stores[state.checkoutStore.toInt()];
  return '${s.address} · ${s.distance}';
}

void main() {
  test('initial', () {
    expect(app.checkoutStoreAddress(sample()), '120 Market St · 0.4 mi');
  });
}
