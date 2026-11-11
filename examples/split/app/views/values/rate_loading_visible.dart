// rateLoadingVisible: rateStatus is loading.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool rateLoadingVisible(State state) => state.rateStatus == RateStatus.loading;

void main() {
  test('rateLoadingVisible', () {
    expect(app.rateLoadingVisible(sample()), false);
    expect(app.rateLoadingVisible(sample({'rateStatus': 'loading'})), true);
  });
}
