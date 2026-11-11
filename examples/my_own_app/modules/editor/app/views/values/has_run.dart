// hasRun: Whether Claude has run in this editor, so the run stats show.
import '../../../.generated/state.dart';

bool hasRun(State state) => state.runMs != 0;
