// fetchRate: Sets rateStatus loading, then remote.loadRate with the CODE of
// draftCurrency (EUR, BRL), which sets rate; rateStatus ready, or failed
// when it returns an error. (Local actions have no network.)

import '../../../.generated/remote.dart';
import '../../../.generated/state.dart';

Future<void> fetchRate(State state, void Function(StateDelta) emit, Remote remote) async {
  if (state.draftCurrency == Currency.usd) {
    emit(StateDelta(rate: 1, rateStatus: RateStatus.ready));
    return;
  }
  var code = 'EUR';
  if (state.draftCurrency == Currency.brl) code = 'BRL';
  emit(StateDelta(rateStatus: RateStatus.loading));
  final error = await remote.loadRate(code);
  emit(StateDelta(rateStatus: error == null ? RateStatus.ready : RateStatus.failed));
}
