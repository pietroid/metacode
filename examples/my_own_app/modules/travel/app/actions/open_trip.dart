// openTrip: Opens a trip from the home list, on its first day with every plan shown.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openTrip(
  State state,
  void Function(StateDelta) emit,
  Core core,
  int index,
) async {
  emit(StateDelta(tripIndex: index, dayIndex: 0, filter: ProgramFilter.all));
  core.navigator.push(Routes.trip);
}

void main() {
  test('openTrip', () async {
    final s = await app.openTrip(sample(dayIndex: 1), 1);
    expect(s.tripIndex, 1);
    expect(s.dayIndex, 0);
    expect(app.navigation, ['push trip']);
  });
}
