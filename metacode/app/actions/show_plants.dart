// showPlants: Jumps the carousel to the plants example.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showPlants(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 3));

void main() {
  test('showPlants jumps to the plants slide', () async {
    final s = await app.showPlants(sample(exampleIndex: 1));
    expect(s.exampleIndex, 3);
  });
}
