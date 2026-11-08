// courseLevel: Course [index]'s level, on its card in the carousel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/tr.dart';

String courseLevel(State state, Labels labels, int index) => tr(state.courses[index].level, labels);

void main() {
  test('courseLevel', () {
    expect(app.courseLevel(sample(), 1), 'Beginner');
  });
}
