// selectedDescription: Selected item description.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String selectedDescription(State state) {
  final MenuItem m = state.menu[state.selectedItem.toInt()];
  return m.description;
}

void main() {
  test('initial', () {
    expect(app.selectedDescription(sample()), 'Rich espresso with steamed milk and a thin layer of foam.');
  });
}
