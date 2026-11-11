// paymentIcon: payment, wallet, gift for index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String paymentIcon(State state, int index) {
  if (index == 0) return 'payment';
  if (index == 1) return 'wallet';
  return 'gift';
}

void main() {
  test('index 1', () {
    expect(app.paymentIcon(sample(), 1), 'wallet');
  });
}
