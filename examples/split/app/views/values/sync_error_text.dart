// syncErrorText: The syncError text.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String syncErrorText(State state) => state.syncError;

void main() {
  test('syncErrorText', () {
    expect(app.syncErrorText(sample()), '');
    expect(app.syncErrorText(sample({'syncError': 'x'})), 'x');
  });
}
