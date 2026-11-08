// openWorkLive: Opens the work example on its own page (the workLive route).
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openWorkLive(State state, Core core) async {
  core.navigator.push(Routes.workLive);
}

void main() {
  test('openWorkLive pushes the work page', () async {
    await app.openWorkLive(sample());
    expect(app.navigation, ['push workLive']);
  });
}
