// suggestionText: Suggested transfer index as '<from> <pays> <to>'.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import 'shared/current_group.dart';
import 'shared/member_balances.dart';
import 'shared/min_transfers.dart';
import '../../models/sample.dart';

String suggestionText(State state, Labels labels, int index) {
  final Group g = currentGroup(state);
  final List<num> b = memberBalances(state, g.id, g.members);
  final List<Transfer> ts = minTransfers(g.id, g.members, b);
  final Transfer t = ts[index];
  return '${t.from} ${labels.pays} ${t.to}';
}

void main() {
  test('suggestionText', () {
    expect(app.suggestionText(sample(), 0), 'Ana pays Ben');
  });
}
