// undoText: "<deleted> "<description>"" for lastDeleted.first, empty when there is none.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String undoText(State state, Labels labels) {
  final List<Expense> d = state.lastDeleted;
  if (d.isEmpty) return '';
  return '${labels.deleted} "${d[0].description}"';
}

void main() {
  test('undoText', () {
    expect(app.undoText(sample()), '');
    final s = sample();
    s.lastDeleted = [s.expenses[0]];
    expect(app.undoText(s), 'Deleted "Dinner at Ramiro"');
  });
}
