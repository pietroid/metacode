// plantsText: A formatted summary of the plant collection.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String plantsText(State state, Labels labels) {
  final n = state.plants.where((Plant p) => p.daysLeft <= 0).length;
  if (n == 0) return labels.allWatered;
  if (n == 1) return '1 ${labels.plantNeedsWaterToday}';
  return '$n ${labels.plantsNeedWaterToday}';
}

void main() {
  test('plantsText', () {
    expect(app.plantsText(sample()), '1 plant needs water today');
  });
}
