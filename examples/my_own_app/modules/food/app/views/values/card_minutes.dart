// cardMinutes: The current recipe's prep time.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_card.dart';
import 'shared/has_card.dart';

String cardMinutes(State state, Labels labels) {
  if (!hasCard(state)) return '';
  return '${currentCard(state).minutes} ${labels.min}';
}

void main() {
  test('cardMinutes', () async {
    expect(app.cardMinutes(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), '20 min');
  });
}
