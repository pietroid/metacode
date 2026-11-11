// storeAddress: Store index address.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String storeAddress(State state, int index) => state.stores[index].address;

void main() {
  test('index 0', () {
    expect(app.storeAddress(sample(), 0), '120 Market St');
  });
}
