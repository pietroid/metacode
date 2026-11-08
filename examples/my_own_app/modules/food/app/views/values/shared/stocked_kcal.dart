// stockedKcal: The kcal of the bought shopping items.
import '../../../../.generated/state.dart';

num stockedKcal(State s) {
  num t = 0;
  for (final i in s.shopping) {
    if (i.bought) t += i.kcal;
  }
  return t;
}
