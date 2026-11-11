// selectedIcon: Selected item icon.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String selectedIcon(State state) {
  final MenuItem m = state.menu[state.selectedItem.toInt()];
  return m.icon;
}

void main() {
  test('initial', () {
    expect(app.selectedIcon(sample()), 'drop');
  });
}
