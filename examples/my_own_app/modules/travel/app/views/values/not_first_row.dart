// notFirstRow: Whether a list row has one above it (RowDivider draws a line).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool notFirstRow(State state, int index) => index > 0;

void main() {
  test('notFirstRow', () {
    expect(app.notFirstRow(sample(), 0), isFalse);
    expect(app.notFirstRow(sample(), 1), isTrue);
  });
}
