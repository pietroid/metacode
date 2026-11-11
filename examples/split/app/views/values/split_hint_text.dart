// splitHintText: the hint label for the current split mode.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String splitHintText(State state, Labels labels) {
  if (state.draftMode == SplitMode.shares) return labels.splitSharesHint;
  if (state.draftMode == SplitMode.exact) return labels.splitExactHint;
  return labels.splitEqualHint;
}

void main() {
  test('splitHintText', () {
    expect(app.splitHintText(sample()), 'Split evenly among the chosen members.');
    expect(app.splitHintText(sample({'draftMode': 'exact'})),
        'Enter what each member owes; it must add up to the total.');
  });
}
