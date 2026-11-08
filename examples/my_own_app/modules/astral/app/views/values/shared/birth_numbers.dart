// birthNumbers: The picked birth day and month as numbers (1 when not
// picked yet), as a record (day, month).
import '../../../../.generated/state.dart';

(int, int) birthNumbers(State state) {
  var day = 1;
  var month = 1;
  if (state.birthDay != '') day = int.parse(state.birthDay);
  if (state.birthMonth != '') month = int.parse(state.birthMonth);
  return (day, month);
}
