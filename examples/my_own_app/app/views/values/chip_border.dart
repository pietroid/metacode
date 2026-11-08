// chipBorder: The edge of ExampleChip [index]: orange while its example is
// shown, else a hairline. Animated with chipFill.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 600, curve: 'easeInOut')
String chipBorder(State state, int index) =>
    state.exampleIndex.round() == index ? 'primary' : 'line';

void main() {
  test('the shown example has an orange edge', () {
    expect(app.chipBorder(sample(exampleIndex: 2), 2), 'primary');
    expect(app.chipBorder(sample(exampleIndex: 2), 1), 'line');
  });
}
