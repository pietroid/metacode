// currentTrip: The open trip (tripIndex, kept inside the list).
import '../../../../.generated/state.dart';

Trip currentTrip(State state) {
  final trips = state.trips;
  var i = state.tripIndex.round();
  if (i >= trips.length) i = trips.length - 1;
  if (i < 0) i = 0;
  return trips[i];
}
