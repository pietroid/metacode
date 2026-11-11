// modeValue: draftMode's name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String modeValue(State state) {
  if (state.draftMode == SplitMode.shares) return 'shares';
  if (state.draftMode == SplitMode.exact) return 'exact';
  return 'equal';
}

void main() {
  test('modeValue', () {
    expect(app.modeValue(sample()), 'equal');
    expect(app.modeValue(sample({'draftMode': 'exact'})), 'exact');
  });
}
