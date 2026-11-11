// The count, rounded: the fixture's shared helper that takes the whole
// state, so a value's reads (manifest `reads`) are found through it.
import '../../../../.generated/state.dart';

int countOf(State state) => state.count.round();
