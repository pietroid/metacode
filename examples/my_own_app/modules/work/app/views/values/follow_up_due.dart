// followUpDue: When a follow-up is due: overdue by n days, today, tomorrow or in n days.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String followUpDue(State state, Labels labels, int index) {
  final d = state.followUps[index].dueIn.round();
  if (d < 0) return '${0 - d}${labels.daysShort} ${labels.overdue}';
  if (d == 0) return labels.dueToday;
  if (d == 1) return labels.dueTomorrow;
  return '${labels.dueIn} $d${labels.daysShort}';
}

void main() {
  test('followUpDue', () {
    expect(app.followUpDue(sample(), 0), '2d overdue');
    expect(app.followUpDue(sample(), 1), 'Due today');
    expect(app.followUpDue(sample(), 2), 'Due in 3d');
  });
}
