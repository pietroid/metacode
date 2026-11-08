// ticketHasImage: Whether the open plan has a photo to show on top of the sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';

bool ticketHasImage(State state) {
  final p = currentProgram(state);
  if (p == null) return false;
  return p.image.isNotEmpty;
}

void main() {
  test('ticketHasImage', () {
    expect(app.ticketHasImage(sample(programIndex: 2)), isFalse);
  });
}
