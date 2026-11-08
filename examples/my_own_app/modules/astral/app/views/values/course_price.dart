// coursePrice: Course [index]'s price, on its card in the carousel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/tr.dart';

String coursePrice(State state, Labels labels, int index) => tr(state.courses[index].price, labels);

void main() {
  test('coursePrice', () {
    expect(app.coursePrice(sample(), 1), '\$149');
  });
}
