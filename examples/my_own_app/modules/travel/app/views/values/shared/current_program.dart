// currentProgram: The plan whose ticket is open (programIndex in the selected
// day's full list), or null when the index is stale.
import '../../../../.generated/state.dart';
import 'current_day.dart';

Program? currentProgram(State state) {
  final programs = currentDay(state).programs;
  final i = state.programIndex.round();
  if (i < 0 || i >= programs.length) return null;
  return programs[i];
}
