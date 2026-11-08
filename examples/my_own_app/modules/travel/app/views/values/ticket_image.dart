// ticketImage: The open plan's photo (the place, or where the transport goes).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';

String ticketImage(State state) {
  final p = currentProgram(state);
  if (p == null) return '';
  return p.image;
}

void main() {
  test('ticketImage', () {
    expect(app.ticketImage(sample(programIndex: 1)), 'pena.jpg');
  });
}
