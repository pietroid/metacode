// formErrorVisible: formError is not empty.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool formErrorVisible(State state) => state.formError != '';

void main() {
  test('formErrorVisible', () {
    expect(app.formErrorVisible(sample()), false);
    expect(app.formErrorVisible(sample({'formError': 'x'})), true);
  });
}
