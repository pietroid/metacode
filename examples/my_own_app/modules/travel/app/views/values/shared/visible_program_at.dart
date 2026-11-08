// visibleProgramAt: The visible plan at a list row, or null when the row is
// stale (the day or filter changed and the list is shorter).
import '../../../../.generated/state.dart';
import 'visible_programs.dart';

Program? visibleProgramAt(State state, int index) {
  final list = visiblePrograms(state);
  if (index < 0 || index >= list.length) return null;
  return list[index];
}
