// paymentSelected: Whether payment index is the chosen method.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool paymentSelected(State state, int index) {
  if (index == 0) return state.paymentMethod == Payment.card;
  if (index == 1) return state.paymentMethod == Payment.wallet;
  return state.paymentMethod == Payment.giftCard;
}

void main() {
  test('initial', () {
    expect(app.paymentSelected(sample(), 0), true);
    expect(app.paymentSelected(sample(), 1), false);
  });
}
