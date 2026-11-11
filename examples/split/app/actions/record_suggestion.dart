// recordSuggestion: Takes suggested transfer index (minTransfers over
// memberBalances for the current group), gives it id 't' +
// millisecondsSinceEpoch, and calls remote.recordSettlement. Error ->
// syncError errorOffline; success -> syncError ''.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/labels.dart';
import '../../.generated/remote.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/current_group.dart';
import '../views/values/shared/member_balances.dart';
import '../views/values/shared/min_transfers.dart';

Future<void> recordSuggestion(State state, void Function(StateDelta) emit, Remote remote, Labels labels, int index) async {
  final Group g = currentGroup(state);
  final List<num> balances = memberBalances(state, g.id, g.members);
  final List<Transfer> list = minTransfers(g.id, g.members, balances);
  if (index < 0 || index >= list.length) return;
  final Transfer s = list[index];
  final Transfer t = Transfer(
    id: 't${DateTime.now().millisecondsSinceEpoch}',
    groupId: g.id,
    from: s.from,
    to: s.to,
    amount: s.amount,
  );
  final error = await remote.recordSettlement(t);
  if (error != null) {
    emit(StateDelta(syncError: labels.errorOffline));
  } else {
    emit(StateDelta(syncError: ''));
  }
}

void main() {
  test('recordSuggestion records the transfer', () async {
    final s = await app.recordSuggestion(sample(), 0);
    expect(s.syncError, '');
    expect(app.remoteCalls, ['recordSettlement']);
  });
}
