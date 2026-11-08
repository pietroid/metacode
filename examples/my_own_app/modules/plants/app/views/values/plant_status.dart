// plantStatus: A color-coded status for a plant's water needs.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String plantStatus(State state, int index, Labels labels) {
  final d = state.plants[index].daysLeft.round();
  if (d <= 0) return labels.waterToday;
  if (d == 1) return labels.tomorrow;
  return '${labels.inDays} $d ${labels.days}';
}

void main() {
  test('plantStatus', () {
    expect(app.plantStatus(sample(), 0), 'Water today');
    expect(app.plantStatus(sample(), 1), 'In 2 days');
  });
}
