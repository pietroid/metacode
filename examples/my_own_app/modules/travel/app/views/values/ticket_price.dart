// ticketPrice: The open ticket's cost ("€20"), or Free.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';
import 'shared/euros.dart';

String ticketPrice(State state, Labels labels) {
  final p = currentProgram(state);
  if (p == null) return '';
  if (p.cost == 0) return labels.free;
  return euros(p.cost, labels);
}

void main() {
  test('ticketPrice', () {
    expect(app.ticketPrice(sample(programIndex: 1)), '€20');
    expect(app.ticketPrice(sample(programIndex: 2)), 'Free');
  });
}
