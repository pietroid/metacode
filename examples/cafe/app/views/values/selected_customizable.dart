// selectedCustomizable: Selected item customizable.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool selectedCustomizable(State state) {
  final MenuItem m = state.menu[state.selectedItem.toInt()];
  return m.customizable;
}

void main() {
  test('initial', () {
    expect(app.selectedCustomizable(sample()), true);
  });
}
