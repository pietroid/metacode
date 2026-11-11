// openOrder: sets selectedOrder to index and pushes the order page.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openOrder(State state, void Function(StateDelta) emit, Core core, int index) async {
  emit(StateDelta(selectedOrder: index));
  core.navigator.push(Routes.order);
}

void main() {
  test('openOrder', () async {
    final s = await app.openOrder(sample(), 1);
    expect(s.selectedOrder, 1);
    expect(app.navigation, ['push order']);
  });
}
