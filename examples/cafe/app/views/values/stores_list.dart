// storesList: the stores.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Store> storesList(State state) => state.stores;

void main() {
  test('3 stores', () {
    expect(app.storesList(sample()).length, 3);
  });
}
