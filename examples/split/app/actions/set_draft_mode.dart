// setDraftMode: Sets draftMode from its name (equal, shares, exact) and clears
// formError.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setDraftMode(State state, void Function(StateDelta) emit, String value) async {
  var m = SplitMode.equal;
  if (value == 'shares') m = SplitMode.shares;
  if (value == 'exact') m = SplitMode.exact;
  emit(StateDelta(draftMode: m, formError: ''));
}

void main() {
  test('setDraftMode', () async {
    final s = await app.setDraftMode(sample(), 'exact');
    expect(s.draftMode, SplitMode.exact);
  });
}
