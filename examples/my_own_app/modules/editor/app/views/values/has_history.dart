// hasHistory: Whether Claude has run on the project in the editor since it
// was loaded or reset, so its totals show in ClaudeBox.
import '../../../.generated/state.dart';

bool hasHistory(State state) => state.projectTurns != 0;
