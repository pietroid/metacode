// selectedDayTitle: The selected day, for the This week header ("Mon 9").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String selectedDayTitle(State state, Labels labels) {
  final names = [labels.mon, labels.tue, labels.wed, labels.thu, labels.fri, labels.sat, labels.sun];
  final d = state.selectedDay.round();
  return '${names[d]} ${9 + d}';
}

void main() {
  test('selectedDayTitle', () {
    expect(app.selectedDayTitle(sample(selectedDay: 2)), 'Wed 11');
  });
}
