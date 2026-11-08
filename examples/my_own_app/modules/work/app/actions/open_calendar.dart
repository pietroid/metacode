// openCalendar: Opens the week's calendar.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openCalendar(State state, Core core) async {
  core.navigator.push(Routes.calendar);
}

void main() {
  test('openCalendar', () async {
    await app.openCalendar(sample());
    expect(app.navigation, ['push calendar']);
  });
}
