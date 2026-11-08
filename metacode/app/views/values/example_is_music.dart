// exampleIsMusic: Whether the music example is currently selected.
import '../../../.generated/state.dart';

bool exampleIsMusic(State state) => state.exampleIndex.round() == 1;
