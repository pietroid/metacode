// close: Closes the editor.
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> close(State state, Core core) async {
  await core.navigator.pop();
}
