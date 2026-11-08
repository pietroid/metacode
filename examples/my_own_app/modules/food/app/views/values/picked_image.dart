// pickedImage: An accepted recipe's illustration.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/image_path.dart';

String pickedImage(State state, int index) => imagePath(state.recipes[state.picked[index].toInt()].image);

void main() {
  test('pickedImage', () async {
    expect(app.pickedImage(sample(goal: Goal.weightLoss, program: 8).copyWith(picked: [12, 0]), 1), endsWith('forkcast_skillet.svg'));
  });
}
