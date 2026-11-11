// What Claude has spent on the example app [name] since it was loaded or
// reset: the current project's (projectCost, projectMs, projectTurns) or
// its entry in `saved`; null when it has none (never opened, or no run yet).
import '../../../../.generated/state.dart';

SavedDraft? historyOf(State state, String name) {
  if (state.projectName == name) {
    if (state.projectTurns == 0) return null;
    return SavedDraft(
        name: name,
        project: state.draft,
        cost: state.projectCost,
        ms: state.projectMs,
        turns: state.projectTurns);
  }
  for (final SavedDraft s in state.saved) {
    if (s.name == name && s.turns != 0) return s;
  }
  return null;
}
