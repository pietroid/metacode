// quantityText: draftQuantity as text.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String quantityText(State state) {
  return '${state.draftQuantity.toInt()}';
}

void main() {
  test('initial', () {
    expect(app.quantityText(sample()), '1');
  });
}
