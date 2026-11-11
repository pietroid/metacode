// fetchRate: Sets rateStatus loading, then GET
// https://open.er-api.com/v6/latest/<CODE> (CODE of draftCurrency, e.g. EUR);
// json rates.USD is the rate -> rate, rateStatus ready. Non-200 or missing ->
// rateStatus failed.

import '../../../.generated/core.dart';
import '../../../.generated/state.dart';

Future<void> fetchRate(State state, void Function(StateDelta) emit, Core core) async {
  if (state.draftCurrency == Currency.usd) {
    emit(StateDelta(rate: 1, rateStatus: RateStatus.ready));
    return;
  }
  var code = 'EUR';
  if (state.draftCurrency == Currency.brl) code = 'BRL';
  emit(StateDelta(rateStatus: RateStatus.loading));
  final r = await core.api.get('https://open.er-api.com/v6/latest/$code');
  final rate = r.ok ? ((r.json as Map)['rates'] as Map)['USD'] : null;
  if (rate is num && rate > 0) {
    emit(StateDelta(rate: rate, rateStatus: RateStatus.ready));
  } else {
    emit(StateDelta(rateStatus: RateStatus.failed));
  }
}
