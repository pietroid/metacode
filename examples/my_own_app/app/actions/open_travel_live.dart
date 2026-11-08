// openTravelLive: Opens the travel example on its own page (the travelLive route).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openTravelLive(State state, Core core) async {
  core.navigator.push(Routes.travelLive);
}

void main() {
  test('openTravelLive pushes the travel page', () async {
    await app.openTravelLive(sample());
    expect(app.navigation, ['push travelLive']);
  });
}
