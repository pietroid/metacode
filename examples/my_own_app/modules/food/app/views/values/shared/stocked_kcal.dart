// stockedKcal: The kcal of the checked shopping items.
import '../../../../.generated/state.dart';

num stockedKcal(State s) {
  num t = 0;
  for (final i in s.shopping) {
    if (i.checked) t += i.kcal;
  }
  return t;
}
