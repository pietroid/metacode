// ticketDetail: The open ticket's detail.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';
import 'shared/tr.dart';

String ticketDetail(State state, Labels labels) {
  final p = currentProgram(state);
  if (p == null) return '';
  return tr(p.ticketDetail, labels);
}

void main() {
  test('ticketDetail', () {
    expect(app.ticketDetail(sample(programIndex: 1)), 'Seat 1A');
    app.locale = 'pt_br';
    expect(app.ticketDetail(sample(programIndex: 1)), 'Assento 1A');
    app.locale = null;
  });
}
