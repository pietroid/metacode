// chipFill: The fill of ExampleChip [index]: orange while its example is
// shown, else the quiet fill. Animated, so a tap fades one chip in and
// the other out.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 600, curve: 'easeInOut')
String chipFill(State state, int index) =>
    state.exampleIndex.round() == index ? 'primary' : 'fill';

void main() {
  test('the shown example is orange, the others fill', () {
    expect(app.chipFill(sample(exampleIndex: 1), 1), 'primary');
    expect(app.chipFill(sample(exampleIndex: 1), 0), 'fill');
  });
}
