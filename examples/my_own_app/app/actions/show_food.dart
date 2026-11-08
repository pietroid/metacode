// showFood: Jumps the carousel to the food example.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showFood(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(exampleIndex: 0));

void main() {
  test('showFood jumps to the food slide', () async {
    final s = await app.showFood(sample(exampleIndex: 2));
    expect(s.exampleIndex, 0);
  });
}
