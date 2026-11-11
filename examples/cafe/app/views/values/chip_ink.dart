// chipInk: Category index chip text - onPrimary when selected, else ink.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/category_at.dart';

@Animated(ms: 200)
String chipInk(State state, int index) {
  if (state.category == categoryAt(index)) return 'onPrimary';
  return 'ink';
}

void main() {
  test('index 1', () {
    expect(app.chipInk(sample(), 1), 'ink');
  });
  test('index 0', () {
    expect(app.chipInk(sample(), 0), 'onPrimary');
  });
}
