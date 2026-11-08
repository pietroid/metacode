// hasCard: Whether the swipe has a card to show: deck not used up, not enough picked yet.
import '../../../../.generated/state.dart';

bool hasCard(State s) =>
    s.deckPos < s.deck.length && s.picked.length < s.days;
