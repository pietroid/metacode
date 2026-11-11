// convertedText: '1 EUR = 1.1187 USD · ≈ $50.34' from rate and the draft amount.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_usd.dart';
import 'shared/parse_amount.dart';

String convertedText(State state) {
  String code = 'USD';
  if (state.draftCurrency == Currency.eur) code = 'EUR';
  if (state.draftCurrency == Currency.brl) code = 'BRL';
  final num usd = parseAmount(state.draftAmount) * state.rate;
  return '1 $code = ${state.rate} USD · ≈ ${formatUsd(usd)}';
}

void main() {
  test('convertedText', () {
    final s = sample({'draftCurrency': 'eur', 'rate': 1.1187, 'draftAmount': '45'});
    final t = app.convertedText(s);
    expect(t.contains('\$50.34'), true);
    expect(t.startsWith('1 EUR = 1.1187 USD'), true);
  });
}
