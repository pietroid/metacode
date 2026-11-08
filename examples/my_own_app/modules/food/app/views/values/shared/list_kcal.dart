// listKcal: The kcal of the whole shopping list.
import '../../../../.generated/state.dart';

num listKcal(State s) {
  num t = 0;
  for (final i in s.shopping) {
    t += i.kcal;
  }
  return t;
}
