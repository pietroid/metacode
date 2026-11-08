// closeModuleSheet: Closes the module's route on top.
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> closeModuleSheet(State state, Core core) async {
  await core.navigator.pop();
}
