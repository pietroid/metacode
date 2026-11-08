// todayEventTitle: One of today's events: title.
import 'package:flutter_test/flutter_test.dart';


import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/event_at.dart';

String todayEventTitle(State state, int index) {
  final e = eventAt(state, 0, index);
  if (e == null) return '';
  return e.title;
}

void main() {
  test('todayEventTitle', () {
    expect(app.todayEventTitle(sample(), 1), 'Budget review');
  });
}
