// sizeExtraText: Price difference of size index: -$0.50, +$0.70, empty for medium.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String sizeExtraText(State state, int index) {
  if (index == 0) return '-\$0.50';
  if (index == 2) return '+\$0.70';
  return '';
}

void main() {
  test('large', () {
    expect(app.sizeExtraText(sample(), 2), '+\$0.70');
  });
  test('medium', () {
    expect(app.sizeExtraText(sample(), 1), '');
  });
}
