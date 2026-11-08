// programImage: A visible plan's photo.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';

String programImage(State state, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return '';
  return p.image;
}

void main() {
  test('programImage', () {
    expect(app.programImage(sample(), 1), 'pena.jpg');
  });
}
