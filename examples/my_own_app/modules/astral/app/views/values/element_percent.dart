// elementPercent: Element [index]'s share as a percentage ("40%"), beside its bar.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/element_amount.dart';

String elementPercent(State state, int index) =>
    '${(elementAmount(state, index) * 100).round()}%';

void main() {
  test('elementPercent', () {
    expect(app.elementPercent(sample(), 0), '20%');
  });
}
