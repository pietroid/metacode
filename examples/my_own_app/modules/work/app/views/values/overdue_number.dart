// overdueNumber: How many open follow-ups are overdue, for its StatTile.
import 'package:flutter_test/flutter_test.dart';


import '../../../.generated/state.dart';
import '../../models/sample.dart';


String overdueNumber(State state) {
  var n = 0;
  for (final f in state.followUps) {
    if (!f.done && f.dueIn < 0) n++;
  }
  return '$n';
}

void main() {
  test('overdueNumber', () {
    expect(app.overdueNumber(sample()), '1');
  });
}
