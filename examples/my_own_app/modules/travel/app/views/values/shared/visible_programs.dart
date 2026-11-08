// visiblePrograms: The selected day's plans that pass the filter (all, only
// transport or only attractions), in order.
import '../../../../.generated/state.dart';
import 'current_day.dart';

List<Program> visiblePrograms(State state) {
  final all = currentDay(state).programs;
  if (state.filter == ProgramFilter.transport) {
    return all.where((Program p) => p.kind == ProgramKind.transport).toList();
  }
  if (state.filter == ProgramFilter.attraction) {
    return all.where((Program p) => p.kind == ProgramKind.attraction).toList();
  }
  return all;
}
