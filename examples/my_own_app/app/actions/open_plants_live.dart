// openPlantsLive: Opens the plants example on its own page (the plantsLive route).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openPlantsLive(State state, Core core) async {
  core.navigator.push(Routes.plantsLive);
}

void main() {
  test('openPlantsLive pushes the plants page', () async {
    await app.openPlantsLive(sample());
    expect(app.navigation, ['push plantsLive']);
  });
}
