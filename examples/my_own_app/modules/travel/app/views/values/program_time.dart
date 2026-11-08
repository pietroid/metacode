// programTime: A visible plan's time.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';

String programTime(State state, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return '';
  return p.time;
}

void main() {
  test('programTime', () {
    expect(app.programTime(sample(), 0), '10:00');
  });
}
