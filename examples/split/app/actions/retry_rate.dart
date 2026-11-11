// retryRate: Runs fetchRate again for draftCurrency.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import 'shared/fetch_rate.dart';

Future<void> retryRate(State state, void Function(StateDelta) emit, Core core) async {
  await fetchRate(state, emit, core);
}

void main() {
  test('retryRate fetches the rate', () async {
    app.api = (method, url, body) => ApiResponse(status: 200, body: '{"rates":{"USD":1.1}}');
    final s = await app.retryRate(sample({'draftCurrency': 'eur', 'rateStatus': 'failed'}));
    expect(s.rateStatus, RateStatus.ready);
    expect(s.rate, 1.1);
  });
}
