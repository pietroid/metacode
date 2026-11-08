// tripTotal: What a whole trip costs: the sum of its days (plans and food).
import '../../../../.generated/state.dart';
import 'day_total.dart';

num tripTotal(Trip trip) {
  num total = 0;
  for (final d in trip.days) {
    total += dayTotal(d);
  }
  return total;
}
