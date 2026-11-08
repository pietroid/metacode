// examplePosition: The 1-based position of the current example in the carousel.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String examplePosition(State state) => '${state.exampleIndex.round() + 1} of 4';

void main() {
  test('examplePosition', () {
    expect(app.examplePosition(sample(exampleIndex: 2)), '3 of 4');
  });
}
