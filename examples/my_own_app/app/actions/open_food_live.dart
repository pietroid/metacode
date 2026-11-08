// openFoodLive: Opens the food example on its own page (the foodLive route).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openFoodLive(State state, Core core) async {
  core.navigator.push(Routes.foodLive);
}

void main() {
  test('openFoodLive pushes the food page', () async {
    await app.openFoodLive(sample());
    expect(app.navigation, ['push foodLive']);
  });
}
