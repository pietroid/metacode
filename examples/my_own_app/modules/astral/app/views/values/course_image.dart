// courseImage: Course [index]'s cover image, on its card in the carousel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String courseImage(State state, int index) => state.courses[index].image;

void main() {
  test('courseImage', () {
    expect(app.courseImage(sample(), 1), 'moon.jpg');
  });
}
