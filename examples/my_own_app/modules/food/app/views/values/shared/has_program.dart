// hasProgram: Whether a program is picked (the plan has something to show).
import '../../../../.generated/state.dart';

bool hasProgram(State s) =>
    s.program >= 0 && s.program < s.programs.length;
