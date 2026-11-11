// draftCheckVisible: draftMode is equal.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool draftCheckVisible(State state) => state.draftMode == SplitMode.equal;

void main() {
  test('draftCheckVisible', () {
    expect(app.draftCheckVisible(sample()), true);
    expect(app.draftCheckVisible(sample({'draftMode': 'shares'})), false);
  });
}
