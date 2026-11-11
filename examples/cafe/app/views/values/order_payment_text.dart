// orderPaymentText: payment label of the selected order.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String orderPaymentText(State state, Labels labels) {
  final int o = state.selectedOrder.toInt();
  if (o < 0 || o >= state.orders.length) return '';
  final Payment p = state.orders[o].payment;
  if (p == Payment.card) return labels.payCard;
  if (p == Payment.wallet) return labels.payWallet;
  return labels.payGiftCard;
}

void main() {
  test('orderPaymentText', () {
    expect(app.orderPaymentText(sample()), 'Visa •••• 4242');
  });
  test('orderPaymentText wallet', () {
    expect(app.orderPaymentText(sample({'selectedOrder': 1})), 'Mobile wallet');
  });
}
