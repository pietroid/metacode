// proteinText: The formatted protein count eaten today.
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';

num _proteinTextEatenProtein(State state) {
  num total = 0;
  for (final f in state.foods) {
    total += f.protein * f.count;
  }
  return total;
}

String proteinText(State state, Labels labels) =>
    '${_proteinTextEatenProtein(state).round()} ${labels.gProteinToday}';
