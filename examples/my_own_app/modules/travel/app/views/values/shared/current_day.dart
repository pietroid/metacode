// currentDay: The selected day of the open trip (dayIndex, kept inside the list).
import '../../../../.generated/state.dart';
import 'current_trip.dart';

TripDay currentDay(State state) {
  final days = currentTrip(state).days;
  var i = state.dayIndex.round();
  if (i >= days.length) i = days.length - 1;
  if (i < 0) i = 0;
  return days[i];
}
