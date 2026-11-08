// programIsTransport: Whether a visible plan is transport (else an attraction).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';

bool programIsTransport(State state, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return false;
  return p.kind == ProgramKind.transport;
}

void main() {
  test('programIsTransport', () {
    expect(app.programIsTransport(sample(), 0), isTrue);
    expect(app.programIsTransport(sample(), 1), isFalse);
  });
}
