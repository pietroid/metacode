// increment: Adds one to the count.
import '../../.generated/state.dart';

Future<void> increment(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(count: state.count + 1));
}
