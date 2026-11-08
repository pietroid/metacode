// pickedList: The accepted recipes, listed when the swipe is over.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Recipe> pickedList(State state) {
  final out = <Recipe>[];
  for (final i in state.picked) {
    out.add(state.recipes[i.toInt()]);
  }
  return out;
}

void main() {
  test('pickedList', () async {
    expect(app.pickedList(sample(goal: Goal.weightLoss, program: 8).copyWith(picked: [12, 0])).length, 2);
  });
}
