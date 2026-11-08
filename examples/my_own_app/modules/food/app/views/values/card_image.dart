// cardImage: The current recipe card's illustration.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_card.dart';
import 'shared/has_card.dart';
import 'shared/image_path.dart';

String cardImage(State state) {
  if (!hasCard(state)) return imagePath('bowl');
  return imagePath(currentCard(state).image);
}

void main() {
  test('cardImage', () async {
    expect(app.cardImage(sample(goal: Goal.weightLoss, program: 8).copyWith(deck: [12, 0], deckPos: 0, picked: [])), endsWith('forkcast_plate.svg'));
  });
}
