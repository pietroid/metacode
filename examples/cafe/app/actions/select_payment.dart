// selectPayment: sets paymentMethod to the payment at index.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectPayment(State state, void Function(StateDelta) emit, int index) async {
  const pays = <Payment>[Payment.card, Payment.wallet, Payment.giftCard];
  if (index < 0 || index >= pays.length) return;
  emit(StateDelta(paymentMethod: pays[index]));
}

void main() {
  test('selectPayment', () async {
    final s = await app.selectPayment(sample(), 1);
    expect(s.paymentMethod, Payment.wallet);
  });
}
