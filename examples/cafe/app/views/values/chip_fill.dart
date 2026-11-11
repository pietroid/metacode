// chipFill: Category index chip fill - primary when selected, else fill.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/category_at.dart';

@Animated(ms: 200)
String chipFill(State state, int index) {
  if (state.category == categoryAt(index)) return 'primary';
  return 'fill';
}

void main() {
  test('index 0', () {
    expect(app.chipFill(sample(), 0), 'primary');
  });
  test('index 1', () {
    expect(app.chipFill(sample(), 1), 'fill');
  });
}
