// ticketTitle: The open ticket's title.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';
import 'shared/tr.dart';

String ticketTitle(State state, Labels labels) {
  final p = currentProgram(state);
  if (p == null) return '';
  return tr(p.title, labels);
}

void main() {
  test('ticketTitle', () {
    expect(app.ticketTitle(sample(programIndex: 1)), 'Palace');
    app.locale = 'pt_br';
    expect(app.ticketTitle(sample(programIndex: 1)), 'Palace PT');
    app.locale = null;
  });
}
