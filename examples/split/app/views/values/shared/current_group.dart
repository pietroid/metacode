// currentGroup: The group whose id is state.selectedGroup (the first group when
// missing).

import '../../../../.generated/state.dart';

Group currentGroup(State state) {
  for (final Group g in state.groups) {
    if (g.id == state.selectedGroup) return g;
  }
  return state.groups[0];
}
