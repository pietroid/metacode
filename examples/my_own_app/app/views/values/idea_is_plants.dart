// ideaIsPlants: Whether the studio idea is the plants chip.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool ideaIsPlants(State state) => state.appKind == AppKind.plants;

void main() {
  test('ideaIsPlants', () {
    expect(app.ideaIsPlants(sample(appKind: AppKind.plants)), isTrue);
    expect(app.ideaIsPlants(sample()), isFalse);
  });
}
