// toggleDraftMember: Flips draftChosen[index] and clears formError.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> toggleDraftMember(State state, void Function(StateDelta) emit, int index) async {
  final List<bool> list = [...state.draftChosen];
  list[index] = !list[index];
  emit(StateDelta(draftChosen: list, formError: ''));
}

void main() {
  test('toggleDraftMember', () async {
    final s = await app.toggleDraftMember(sample(), 0);
    expect(s.draftChosen, [false, true, true, true]);
  });
}
