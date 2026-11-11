// What Claude has spent on every example app together since each was
// loaded or reset: the current project's history plus every saved one's,
// as one SavedDraft (its name and project unused); null when nothing yet.
import '../../../../.generated/state.dart';

SavedDraft? allHistory(State state) {
  num cost = state.projectCost;
  num ms = state.projectMs;
  num turns = state.projectTurns;
  for (final SavedDraft s in state.saved) {
    if (s.name != state.projectName) {
      cost = cost + s.cost;
      ms = ms + s.ms;
      turns = turns + s.turns;
    }
  }
  if (turns == 0) return null;
  return SavedDraft(
      name: '', project: state.draft, cost: cost, ms: ms, turns: turns);
}
