// paymentOptions: The payment methods.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Payment> paymentOptions(State state) {
  return [Payment.card, Payment.wallet, Payment.giftCard];
}

void main() {
  test('3', () {
    expect(app.paymentOptions(sample()).length, 3);
  });
}
