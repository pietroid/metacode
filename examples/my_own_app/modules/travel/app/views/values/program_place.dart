// programPlace: A visible plan's place.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';
import 'shared/tr.dart';

String programPlace(State state, Labels labels, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return '';
  return tr(p.place, labels);
}

void main() {
  test('programPlace', () {
    expect(app.programPlace(sample(), 0), 'Somewhere');
    app.locale = 'pt_br';
    expect(app.programPlace(sample(), 0), 'Algum lugar');
    app.locale = null;
  });
}
