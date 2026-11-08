// courseTitle: Course [index]'s title, on its card in the carousel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/tr.dart';

String courseTitle(State state, Labels labels, int index) => tr(state.courses[index].title, labels);

void main() {
  test('courseTitle', () {
    expect(app.courseTitle(sample(), 1), 'Moon');
  });
}
