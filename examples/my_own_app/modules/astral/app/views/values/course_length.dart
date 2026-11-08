// courseLength: Course [index]'s length ("6 lessons · 4 weeks"), on its card in the carousel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/tr.dart';

String courseLength(State state, Labels labels, int index) => tr(state.courses[index].length, labels);

void main() {
  test('courseLength', () {
    expect(app.courseLength(sample(), 1), '6 lessons');
  });
}
