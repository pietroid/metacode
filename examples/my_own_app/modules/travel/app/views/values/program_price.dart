// programPrice: A visible plan's cost ("€20"), or Free.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';
import 'shared/euros.dart';

String programPrice(State state, Labels labels, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return '';
  if (p.cost == 0) return labels.free;
  return euros(p.cost, labels);
}

void main() {
  test('programPrice', () {
    expect(app.programPrice(sample(), 1), '€20');
    expect(app.programPrice(sample(), 2), 'Free');
    app.locale = 'pt_br';
    expect(app.programPrice(sample(), 2), 'Grátis');
    app.locale = null;
  });
}
