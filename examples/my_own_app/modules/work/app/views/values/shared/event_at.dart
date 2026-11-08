// eventAt: A day's event at a row index, or null when the row is stale (the
// day changed and its list is shorter than the rows still shown).
import '../../../../.generated/state.dart';
import 'events_on.dart';

Event? eventAt(State state, num day, int index) {
  final es = eventsOn(state, day);
  if (index < 0 || index >= es.length) return null;
  return es[index];
}
