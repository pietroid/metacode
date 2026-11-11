// setDraftMemberInput: Writes the text into draftShares[index] in shares mode
// or draftExact[index] in exact mode; clears formError.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setDraftMemberInput(State state, void Function(StateDelta) emit, int index, String value) async {
  if (state.draftMode == SplitMode.shares) {
    final List<String> list = [...state.draftShares];
    list[index] = value;
    emit(StateDelta(draftShares: list, formError: ''));
  } else if (state.draftMode == SplitMode.exact) {
    final List<String> list = [...state.draftExact];
    list[index] = value;
    emit(StateDelta(draftExact: list, formError: ''));
  }
}

void main() {
  test('setDraftMemberInput exact', () async {
    final s = await app.setDraftMemberInput(sample({'draftMode': 'exact'}), 1, '20');
    expect(s.draftExact[1], '20');
  });
}
