// makeButtonText: The label of the studio's make button (make, making, make again).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String makeButtonText(State state, Labels labels) {
  if (state.buildStep >= 1 && state.buildStep <= 4) return labels.making;
  if (state.buildStep >= 5) return labels.makeItAgain;
  return labels.makeMyApp;
}

void main() {
  test('makeButtonText', () {
    expect(app.makeButtonText(sample(buildStep: 3)), 'Making…');
    expect(app.makeButtonText(sample(buildStep: 5)), 'Make it again');
  });
}
