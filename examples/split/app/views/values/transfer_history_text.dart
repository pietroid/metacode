// transferHistoryText: '<from> <paid> <to> $20.00' for the selected group's transfer index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'group_transfers.dart';
import 'shared/format_usd.dart';

String transferHistoryText(State state, Labels labels, int index) {
  final xs = groupTransfers(state);
  if (index < 0 || index >= xs.length) return '';
  final t = xs[index];
  return '${t.from} ${labels.paid} ${t.to} ${formatUsd(t.amount)}';
}

void main() {
  test('transferHistoryText', () {
    expect(app.transferHistoryText(sample(), 0), 'Dev paid Ana \$20.00');
    expect(app.transferHistoryText(sample(), 5), '');
  });
}
