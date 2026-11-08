// openSheet: Opens the bottom sheet.
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> openSheet(State state, Core core) async {
  await core.navigator.push(Routes.sheet);
}
