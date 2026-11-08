// currentCard: The recipe on the current swipe card (check hasCard first).
import '../../../../.generated/state.dart';

Recipe currentCard(State s) =>
    s.recipes[s.deck[s.deckPos.toInt()].toInt()];
