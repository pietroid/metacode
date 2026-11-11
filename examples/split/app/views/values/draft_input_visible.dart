// draftInputVisible: draftMode is shares or exact.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool draftInputVisible(State state) => state.draftMode != SplitMode.equal;

void main() {
  test('draftInputVisible', () {
    expect(app.draftInputVisible(sample()), false);
    expect(app.draftInputVisible(sample({'draftMode': 'exact'})), true);
  });
}
