// dayTotal: What a day costs: every plan plus its food budget.
import '../../../../.generated/state.dart';

num dayTotal(TripDay day) {
  num total = day.food;
  for (final p in day.programs) {
    total += p.cost;
  }
  return total;
}
