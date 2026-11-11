// undoDelete: Calls remote.addExpense with lastDeleted.first (nothing when
// empty). Success -> lastDeleted []. Error -> syncError errorOffline.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/labels.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> undoDelete(State state, void Function(StateDelta) emit, Remote remote, Labels labels) async {
  if (state.lastDeleted.isEmpty) return;
  final error = await remote.addExpense(state.lastDeleted[0]);
  if (error != null) {
    emit(StateDelta(syncError: labels.errorOffline));
  } else {
    emit(StateDelta(lastDeleted: []));
  }
}

void main() {
  test('undoDelete restores and clears', () async {
    final base = sample();
    final s = await app.undoDelete(sample({'lastDeleted': [base.expenses[0].toJson()]}));
    expect(s.lastDeleted.length, 0);
  });
}
