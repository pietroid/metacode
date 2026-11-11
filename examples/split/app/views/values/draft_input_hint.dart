// draftInputHint: sharesHint in shares mode, exactHint in exact mode.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String draftInputHint(State state, Labels labels) {
  if (state.draftMode == SplitMode.shares) return labels.sharesHint;
  if (state.draftMode == SplitMode.exact) return labels.exactHint;
  return '';
}

void main() {
  test('draftInputHint', () {
    expect(app.draftInputHint(sample({'draftMode': 'shares'})), 'Shares');
    expect(app.draftInputHint(sample({'draftMode': 'exact'})), 'Amount');
  });
}
