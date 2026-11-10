// rename: Sets the nickname (remote state: applied here at once, then
// synced up).
import '../../.generated/state.dart';

Future<void> rename(State state, void Function(StateDelta) emit) async {
  emit(StateDelta(nickname: 'grace'));
}
