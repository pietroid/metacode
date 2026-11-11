// milkLabel: milkWhole, milkOat, milkAlmond, milkNone for index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String milkLabel(State state, Labels labels, int index) {
  if (index == 0) return labels.milkWhole;
  if (index == 1) return labels.milkOat;
  if (index == 2) return labels.milkAlmond;
  return labels.milkNone;
}

void main() {
  test('index 3', () {
    expect(app.milkLabel(sample(), 3), 'No milk');
  });
}
