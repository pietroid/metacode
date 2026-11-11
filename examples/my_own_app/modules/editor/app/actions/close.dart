// close: Closes the page on top: the editor (back to ProjectPage), or
// ProjectPage (back to the site).
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> close(State state, Core core) async {
  await core.navigator.pop();
}
