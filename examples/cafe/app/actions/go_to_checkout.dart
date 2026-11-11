// goToCheckout: pops the cart sheet, sets checkoutStore to favoriteStore and
// pushes checkout.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> goToCheckout(State state, void Function(StateDelta) emit, Core core) async {
  await core.navigator.pop();
  emit(StateDelta(checkoutStore: state.favoriteStore));
  core.navigator.push(Routes.checkout);
}

void main() {
  test('goToCheckout', () async {
    final s = await app.goToCheckout(sample({'favoriteStore': 1}));
    expect(s.checkoutStore, 1);
    expect(app.navigation, ['pop', 'push checkout']);
  });
}
