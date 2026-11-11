// convertedVisible: rate ready, a non-USD currency and an amount above 0.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/parse_amount.dart';

bool convertedVisible(State state) {
  if (state.rateStatus != RateStatus.ready) return false;
  if (state.draftCurrency == Currency.usd) return false;
  return parseAmount(state.draftAmount) > 0;
}

void main() {
  test('convertedVisible', () {
    expect(app.convertedVisible(sample()), false);
    expect(app.convertedVisible(sample({'draftCurrency': 'eur', 'draftAmount': '45'})), true);
    expect(app.convertedVisible(sample({'draftCurrency': 'eur'})), false);
  });
}
