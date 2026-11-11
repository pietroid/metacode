// currencyValue: draftCurrency as 'USD', 'EUR' or 'BRL'.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String currencyValue(State state) {
  if (state.draftCurrency == Currency.eur) return 'EUR';
  if (state.draftCurrency == Currency.brl) return 'BRL';
  return 'USD';
}

void main() {
  test('currencyValue', () {
    expect(app.currencyValue(sample()), 'USD');
    expect(app.currencyValue(sample({'draftCurrency': 'brl'})), 'BRL');
  });
}
