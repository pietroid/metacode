// showShopping: Opens the shopping list over the plan.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showShopping(State state, Core core) async {
  core.navigator.push(Routes.shopping);
}

void main() {
  test('showShopping', () async {
    await app.showShopping(sample(stage: Stage.plan));
    expect(app.navigation, ['push shopping']);
  });
}
