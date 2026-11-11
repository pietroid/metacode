// setDraftCurrency: Sets draftCurrency from 'USD'/'EUR'/'BRL'. USD -> rate 1,
// rateStatus ready. Otherwise runs fetchRate.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/fetch_rate.dart';

Future<void> setDraftCurrency(State state, void Function(StateDelta) emit, Remote remote, String value) async {
  if (value == 'USD') {
    emit(StateDelta(draftCurrency: Currency.usd, rate: 1, rateStatus: RateStatus.ready));
    return;
  }
  final Currency c = value == 'BRL' ? Currency.brl : Currency.eur;
  emit(StateDelta(draftCurrency: c));
  await fetchRate(state.copyWith(draftCurrency: c), emit, remote);
}

void main() {
  test('setDraftCurrency USD', () async {
    final s = await app.setDraftCurrency(sample({'draftCurrency': 'eur', 'rate': 2}), 'USD');
    expect(s.draftCurrency, Currency.usd);
    expect(s.rate, 1);
    expect(s.rateStatus, RateStatus.ready);
  });
}
