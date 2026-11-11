// runTimeText: How long the last Claude run took, in minutes (next to a
// timer icon).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/format_minutes.dart';

String runTimeText(State state, Labels labels) =>
    formatMinutes(state.runMs, labels);

void main() {
  test('runTimeText in minutes', () {
    expect(app.runTimeText(sample().copyWith(runMs: 90000)), '1.5 min');
  });
}
