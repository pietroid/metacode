// hasShopping: Whether a shopping list exists.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool hasShopping(State state) => state.shopping.isNotEmpty;

void main() {
  test('hasShopping', () async {
    expect(app.hasShopping(sample()), false);
  });
}
