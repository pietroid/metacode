// todayEventImportant: Whether a today's event is important.
import 'package:flutter_test/flutter_test.dart';


import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/event_at.dart';

bool todayEventImportant(State state, int index) {
  final e = eventAt(state, 0, index);
  if (e == null) return false;
  return e.important;
}

void main() {
  test('todayEventImportant', () {
    expect(app.todayEventImportant(sample(), 1), isTrue);
  });
}
