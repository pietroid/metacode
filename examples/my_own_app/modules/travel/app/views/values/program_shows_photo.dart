// programShowsPhoto: Whether a visible plan shows its photo in the row: an attraction that has one (transport shows its icon).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';

bool programShowsPhoto(State state, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return false;
  return p.kind == ProgramKind.attraction && p.image.isNotEmpty;
}

void main() {
  test('programShowsPhoto', () {
    expect(app.programShowsPhoto(sample(), 0), isFalse);
    expect(app.programShowsPhoto(sample(), 1), isTrue);
    expect(app.programShowsPhoto(sample(), 2), isFalse);
  });
}
