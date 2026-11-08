// pickedName: An accepted recipe's name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/pick.dart';

String pickedName(State state, Labels labels, int index) {
  final r = state.recipes[state.picked[index].toInt()];
  return pick(labels, r.name, r.namePt);
}

void main() {
  test('pickedName', () async {
    expect(app.pickedName(sample(goal: Goal.weightLoss, program: 8).copyWith(picked: [12, 0]), 1), 'Tofu & Broccoli Stir-fry');
  });
}
