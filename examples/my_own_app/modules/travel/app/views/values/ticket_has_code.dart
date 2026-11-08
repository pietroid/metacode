// ticketHasCode: Whether the open plan has a ticket (else no ticket is needed).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';

bool ticketHasCode(State state) {
  final p = currentProgram(state);
  if (p == null) return false;
  return p.ticketCode.isNotEmpty;
}

void main() {
  test('ticketHasCode', () {
    expect(app.ticketHasCode(sample()), isTrue);
    expect(app.ticketHasCode(sample(programIndex: 2)), isFalse);
  });
}
