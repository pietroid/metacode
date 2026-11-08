// swatch: A Swatch's color: black when the count is its `index`, else
// white. Animated, so it eases between the two.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

@Animated(ms: 100, curve: 'linear')
String swatch(State state, int index) =>
    state.count == index ? '#000000' : '#FFFFFF';

void main() {
  test('black on its count', () {
    expect(app.swatch(sample(count: 1), 1), '#000000');
    expect(app.swatch(sample(), 1), '#FFFFFF');
  });
}
