// ticketPlace: The open ticket's place.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';
import 'shared/tr.dart';

String ticketPlace(State state, Labels labels) {
  final p = currentProgram(state);
  if (p == null) return '';
  return tr(p.place, labels);
}

void main() {
  test('ticketPlace', () {
    expect(app.ticketPlace(sample(programIndex: 1)), 'Somewhere');
    app.locale = 'pt_br';
    expect(app.ticketPlace(sample(programIndex: 1)), 'Algum lugar');
    app.locale = null;
  });
}
