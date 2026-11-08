// resetAstral: Starts the astral example over: its state back to its first launch, its open sheets closed.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> resetAstral(State state, Core core) async {
  await core.modules.reset('astral');
}

void main() {
  test('resetAstral resets the astral module', () async {
    await app.resetAstral(sample());
    expect(app.modulesReset, ['astral']);
  });
}
