// syncErrorVisible: True when syncError is not empty.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool syncErrorVisible(State state) => state.syncError.isNotEmpty;

void main() {
  test('syncErrorVisible', () {
    expect(app.syncErrorVisible(sample()), false);
    expect(app.syncErrorVisible(sample({'syncError': 'x'})), true);
  });
}
