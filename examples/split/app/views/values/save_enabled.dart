// saveEnabled: rateStatus is ready and saveStatus is not saving.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool saveEnabled(State state) =>
    state.rateStatus == RateStatus.ready && state.saveStatus != SaveStatus.saving;

void main() {
  test('saveEnabled', () {
    expect(app.saveEnabled(sample()), true);
    expect(app.saveEnabled(sample({'rateStatus': 'failed'})), false);
    expect(app.saveEnabled(sample({'saveStatus': 'saving'})), false);
  });
}
