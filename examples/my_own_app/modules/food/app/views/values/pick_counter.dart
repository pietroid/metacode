// pickCounter: How many recipes are picked of the days asked for.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String pickCounter(State state, Labels labels) => '${state.picked.length} ${labels.of} ${state.days}';

void main() {
  test('pickCounter', () async {
    expect(app.pickCounter(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), '0 of 5');
  });
}
