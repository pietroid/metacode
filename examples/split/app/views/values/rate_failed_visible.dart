// rateFailedVisible: rateStatus is failed.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool rateFailedVisible(State state) => state.rateStatus == RateStatus.failed;

void main() {
  test('rateFailedVisible', () {
    expect(app.rateFailedVisible(sample()), false);
    expect(app.rateFailedVisible(sample({'rateStatus': 'failed'})), true);
  });
}
