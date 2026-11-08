// programHasTicket: Whether a visible plan has a ticket to show.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';

bool programHasTicket(State state, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return false;
  return p.ticketCode.isNotEmpty;
}

void main() {
  test('programHasTicket', () {
    expect(app.programHasTicket(sample(), 0), isTrue);
    expect(app.programHasTicket(sample(), 2), isFalse);
  });
}
