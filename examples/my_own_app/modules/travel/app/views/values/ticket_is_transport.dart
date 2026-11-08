// ticketIsTransport: Whether the open ticket is for transport.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';

bool ticketIsTransport(State state) {
  final p = currentProgram(state);
  if (p == null) return false;
  return p.kind == ProgramKind.transport;
}

void main() {
  test('ticketIsTransport', () {
    expect(app.ticketIsTransport(sample(programIndex: 1)), isFalse);
  });
}
