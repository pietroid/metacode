// programTitle: A visible plan's title.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_program_at.dart';
import 'shared/tr.dart';

String programTitle(State state, Labels labels, int index) {
  final p = visibleProgramAt(state, index);
  if (p == null) return '';
  return tr(p.title, labels);
}

void main() {
  test('programTitle', () {
    expect(app.programTitle(sample(), 0), 'Train');
    app.locale = 'pt_br';
    expect(app.programTitle(sample(), 0), 'Train PT');
    app.locale = null;
  });
}
