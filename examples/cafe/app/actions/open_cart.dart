// openCart: pushes the cart sheet.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openCart(State state, Core core) async {
  core.navigator.push(Routes.cart);
}

void main() {
  test('openCart', () async {
    await app.openCart(sample());
    expect(app.navigation, ['push cart']);
  });
}
