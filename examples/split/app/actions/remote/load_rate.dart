// loadRate: GET https://open.er-api.com/v6/latest/<value> (EUR, BRL); json
// rates.USD -> rate (remote). Refuses (noRate) a failed request or a missing
// rate.

import '../../../.generated/api.dart';
import '../../../.generated/remote_state.dart';

Future<void> loadRate(State state, void Function(StateDelta) emit, Api api, String value) async {
  if (value != 'EUR' && value != 'BRL') throw RemoteError('badCurrency');
  final r = await api.get('https://open.er-api.com/v6/latest/$value');
  final rate = r.ok ? ((r.json as Map)['rates'] as Map)['USD'] : null;
  if (rate is num && rate > 0) {
    emit(StateDelta(rate: rate));
  } else {
    throw RemoteError('noRate');
  }
}
