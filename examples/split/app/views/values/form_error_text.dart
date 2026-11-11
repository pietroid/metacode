// formErrorText: the formError text.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String formErrorText(State state) => state.formError;

void main() {
  test('formErrorText', () {
    expect(app.formErrorText(sample()), '');
    expect(app.formErrorText(sample({'formError': 'x'})), 'x');
  });
}
