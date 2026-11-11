// draftMemberChosen: draftChosen[index], false when out of range.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool draftMemberChosen(State state, int index) {
  final c = state.draftChosen;
  if (index < 0 || index >= c.length) return false;
  return c[index];
}

void main() {
  test('draftMemberChosen', () {
    expect(app.draftMemberChosen(sample(), 0), true);
    expect(app.draftMemberChosen(sample(), 9), false);
  });
}
