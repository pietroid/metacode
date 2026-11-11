// selectedColor: Selected item color.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String selectedColor(State state) {
  final MenuItem m = state.menu[state.selectedItem.toInt()];
  return m.color;
}

void main() {
  test('initial', () {
    expect(app.selectedColor(sample()), '#C89F7A');
  });
}
