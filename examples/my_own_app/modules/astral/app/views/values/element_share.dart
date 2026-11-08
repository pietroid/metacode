// elementShare: How much of the chart is element [index] (0 fire, 1 earth, 2 air, 3 water), 0 to 1, for its bar.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/element_amount.dart';

double elementShare(State state, int index) => elementAmount(state, index);

void main() {
  test('elementShare', () {
    expect(app.elementShare(sample(), 0), 0.2);
    expect(app.elementShare(sample(), 3), 0.4);
  });
}
