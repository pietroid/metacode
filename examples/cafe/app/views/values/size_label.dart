// sizeLabel: sizeSmall, sizeMedium, sizeLarge for index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String sizeLabel(State state, Labels labels, int index) {
  if (index == 0) return labels.sizeSmall;
  if (index == 1) return labels.sizeMedium;
  return labels.sizeLarge;
}

void main() {
  test('index 0', () {
    expect(app.sizeLabel(sample(), 0), 'Small');
  });
}
