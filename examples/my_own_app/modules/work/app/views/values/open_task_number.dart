// openTaskNumber: How many to-dos are open, for its StatTile.
import 'package:flutter_test/flutter_test.dart';


import '../../../.generated/state.dart';
import '../../models/sample.dart';


String openTaskNumber(State state) {
  var n = 0;
  for (final t in state.tasks) {
    if (!t.done) n++;
  }
  return '$n';
}

void main() {
  test('openTaskNumber', () {
    expect(app.openTaskNumber(sample()), '1');
  });
}
