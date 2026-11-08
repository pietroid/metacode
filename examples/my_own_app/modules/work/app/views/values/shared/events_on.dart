// eventsOn: The events of one day of the week (0 = Monday), in order.
import '../../../../.generated/state.dart';

List<Event> eventsOn(State state, num day) =>
    state.events.where((Event e) => e.day == day).toList();
