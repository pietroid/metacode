// selectedName: Selected menu item name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String selectedName(State state) {
  final MenuItem m = state.menu[state.selectedItem.toInt()];
  return m.name;
}

void main() {
  test('initial', () {
    expect(app.selectedName(sample()), 'Caffè Latte');
  });
}
