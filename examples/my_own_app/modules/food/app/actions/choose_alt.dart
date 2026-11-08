// chooseAlt: Switches to one of the other matching programs.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';
import '../views/values/shared/alt_indexes.dart';

Future<void> chooseAlt(State state, void Function(StateDelta) emit, int index) async {
  emit(StateDelta(program: altIndexes(state)[index]));
}

void main() {
  test('chooseAlt', () async {
    expect((await app.chooseAlt(sample(goal: Goal.weightLoss, program: 8).copyWith(matches: [8, 9, 10]), 1)).program, 10);
  });
}
