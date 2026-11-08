// withFoodAdded: The trips with an amount added to the selected day's food
// budget (state's own copy, changed in place), ready to emit.
import '../../../.generated/state.dart';
import '../../views/values/shared/current_day.dart';

List<Trip> withFoodAdded(State state, num amount) {
  final day = currentDay(state);
  day.food = day.food + amount;
  return state.trips;
}
