// paymentLabel: payCard, payWallet, payGiftCard for index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String paymentLabel(State state, Labels labels, int index) {
  if (index == 0) return labels.payCard;
  if (index == 1) return labels.payWallet;
  return labels.payGiftCard;
}

void main() {
  test('index 0', () {
    expect(app.paymentLabel(sample(), 0), 'Visa •••• 4242');
  });
}
