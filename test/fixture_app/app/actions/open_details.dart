// openDetails: Opens the details page.
import '../../.generated/core.dart';
import '../../.generated/state.dart';

Future<void> openDetails(State state, Core core) async {
  await core.navigator.push(Routes.details);
}
