// kcalTarget: The kcal the planned days need: the program's daily kcal times the days (the whole list's kcal when no program is picked).
import '../../../../.generated/state.dart';
import 'has_program.dart';

num kcalTarget(State s) {
  if (hasProgram(s)) return s.programs[s.program.toInt()].kcal * s.days;
  num t = 0;
  for (final i in s.shopping) {
    t += i.kcal;
  }
  return t;
}
