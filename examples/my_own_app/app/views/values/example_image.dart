// exampleImage: The hero image asset path for the currently visible example.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String exampleImage(State state) {
  final i = state.exampleIndex.round();
  if (i == 1) return 'examples/my_own_app/app/views/style/images/guitar.jpg';
  if (i == 3) return 'examples/my_own_app/app/views/style/images/plant.jpg';
  return 'examples/my_own_app/app/views/style/images/food.jpg';
}

void main() {
  test('exampleImage', () {
    expect(
      app.exampleImage(sample(exampleIndex: 0)),
      'examples/my_own_app/app/views/style/images/food.jpg',
    );
  });
}
