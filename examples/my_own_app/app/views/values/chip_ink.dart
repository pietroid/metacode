// chipInk: The label color of ExampleChip [index]: white on the orange
// fill while its example is shown, else secondary ink.
// Animated with chipFill.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 600, curve: 'easeInOut')
String chipInk(State state, int index) =>
    state.exampleIndex.round() == index ? 'onPrimary' : 'ink2';

void main() {
  test('the shown example reads on its orange fill', () {
    expect(app.chipInk(sample(), 0), 'onPrimary');
    expect(app.chipInk(sample(), 1), 'ink2');
  });
}
