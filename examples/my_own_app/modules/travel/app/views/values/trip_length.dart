// tripLength: How many days a trip lasts ("16 days", "1 day").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String tripLength(State state, Labels labels, int index) {
  final days = state.trips[index].days;
  final n = days.length;
  if (n == 1) return '1 ${labels.oneDay}';
  return '$n ${labels.days}';
}

void main() {
  test('tripLength', () {
    expect(app.tripLength(sample(), 0), '2 days');
    expect(app.tripLength(sample(), 1), '1 day');
  });
}
