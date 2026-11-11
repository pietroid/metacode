// themeLabel: label of theme choice index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String themeLabel(State state, Labels labels, int index) {
  if (index == 0) return labels.themeSystem;
  if (index == 1) return labels.themeLight;
  return labels.themeDark;
}

void main() {
  test('themeLabel', () {
    expect(app.themeLabel(sample(), 2), 'Dark');
    expect(app.themeLabel(sample(), 0), 'System');
  });
}
