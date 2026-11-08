// ticketKind: The open ticket's kind ("Transport" or "Attraction").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';

String ticketKind(State state, Labels labels) {
  final p = currentProgram(state);
  if (p == null) return '';
  if (p.kind == ProgramKind.transport) return labels.transport;
  return labels.attraction;
}

void main() {
  test('ticketKind', () {
    expect(app.ticketKind(sample()), 'Transport');
  });
}
