// ticketNote: The open ticket's note.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';
import 'shared/tr.dart';

String ticketNote(State state, Labels labels) {
  final p = currentProgram(state);
  if (p == null) return '';
  return tr(p.ticketNote, labels);
}

void main() {
  test('ticketNote', () {
    expect(app.ticketNote(sample(programIndex: 1)), 'Be early');
    app.locale = 'pt_br';
    expect(app.ticketNote(sample(programIndex: 1)), 'Chegue cedo');
    app.locale = null;
  });
}
