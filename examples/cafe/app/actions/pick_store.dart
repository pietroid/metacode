// pickStore: sets checkoutStore to index and pops the dialog.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> pickStore(State state, void Function(StateDelta) emit, Core core, int index) async {
  emit(StateDelta(checkoutStore: index));
  await core.navigator.pop();
}

void main() {
  test('pickStore', () async {
    final s = await app.pickStore(sample(), 2);
    expect(s.checkoutStore, 2);
    expect(app.navigation, ['pop']);
  });
}
