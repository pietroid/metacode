// stepLabel: statusPlaced, statusPreparing, statusReady for index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String stepLabel(State state, Labels labels, int index) {
  if (index == 0) return labels.statusPlaced;
  if (index == 1) return labels.statusPreparing;
  return labels.statusReady;
}

void main() {
  test('index 1', () {
    expect(app.stepLabel(sample(), 1), 'Preparing');
  });
}
