// cardIngredients: The current recipe's ingredients, in one line.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_card.dart';
import 'shared/has_card.dart';
import 'shared/pick.dart';

String cardIngredients(State state, Labels labels) {
  if (!hasCard(state)) return '';
  final names = <String>[];
  for (final i in currentCard(state).ingredients) {
    names.add(pick(labels, i.name, i.namePt));
  }
  return names.join(' · ');
}

void main() {
  test('cardIngredients', () async {
    expect(app.cardIngredients(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), startsWith('Salmon fillets · Asparagus'));
  });
}
