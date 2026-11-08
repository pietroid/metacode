// ticketCode: The open ticket's booking code.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';

String ticketCode(State state) {
  final p = currentProgram(state);
  if (p == null) return '';
  return p.ticketCode;
}

void main() {
  test('ticketCode', () {
    expect(app.ticketCode(sample(programIndex: 1)), 'PENA-1');
  });
}
