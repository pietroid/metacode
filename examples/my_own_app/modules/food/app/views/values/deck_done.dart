// deckDone: Whether the swipe is over: deck used up or enough recipes picked.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/has_card.dart';

bool deckDone(State state) => !hasCard(state);

void main() {
  test('deckDone', () async {
    expect(app.deckDone(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), false);
    expect(app.deckDone(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: []).copyWith(deckPos: 2)), true);
  });
}
