// openDialog: Opens the dialog.
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> openDialog(State state, Core core) async {
  await core.navigator.push(Routes.dialog);
}
