// storeName: Store index name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String storeName(State state, int index) => state.stores[index].name;

void main() {
  test('index 1', () {
    expect(app.storeName(sample(), 1), 'Riverside');
  });
}
