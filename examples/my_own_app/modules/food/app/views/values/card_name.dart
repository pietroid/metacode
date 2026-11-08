// cardName: The current recipe card's name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_card.dart';
import 'shared/has_card.dart';
import 'shared/pick.dart';

String cardName(State state, Labels labels) {
  if (!hasCard(state)) return '';
  final r = currentCard(state);
  return pick(labels, r.name, r.namePt);
}

void main() {
  test('cardName', () async {
    expect(app.cardName(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), 'Salmon, Asparagus & Lemon');
  });
}
