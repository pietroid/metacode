// openModuleSheet: Opens the module's bottom sheet.
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> openModuleSheet(State state, Core core) async {
  await core.navigator.push(Routes.sheet);
}
