// pickupLabel: pickupNow, pickupIn15, pickupIn30 for index.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String pickupLabel(State state, Labels labels, int index) {
  if (index == 0) return labels.pickupNow;
  if (index == 1) return labels.pickupIn15;
  return labels.pickupIn30;
}

void main() {
  test('index 1', () {
    expect(app.pickupLabel(sample(), 1), 'In 15 minutes');
  });
}
