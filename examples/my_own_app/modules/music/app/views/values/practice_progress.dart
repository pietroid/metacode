// practiceProgress: The share of the 10-minute daily practice goal done.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

double _practiceProgressCapAtOne(num p) {
  final double d = p.toDouble();
  if (d > 1) return 1.0;
  return d;
}

double practiceProgress(State state) {
  return _practiceProgressCapAtOne(state.practiceMinutes / 10);
}

void main() {
  test('practiceProgress', () {
    expect(app.practiceProgress(sample(practiceMinutes: 20)), 1.0);
  });
}
