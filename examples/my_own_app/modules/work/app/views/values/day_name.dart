// dayName: A day's short weekday name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String dayName(State state, Labels labels, int index) {
  final names = [labels.mon, labels.tue, labels.wed, labels.thu, labels.fri, labels.sat, labels.sun];
  return names[index];
}

void main() {
  test('dayName', () {
    expect(app.dayName(sample(), 3), 'Thu');
  });
}
