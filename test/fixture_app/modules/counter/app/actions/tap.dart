// tap: Counts a tap.
import '../../.generated/state.dart';

Future<void> tap(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(taps: state.taps + 1));
}
