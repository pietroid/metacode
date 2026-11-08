// ticketWhen: When the open ticket is for: the day's date and the time ("Sat, Nov 15 · 10:00").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_program.dart';
import 'shared/current_day.dart';
import 'shared/tr.dart';

String ticketWhen(State state, Labels labels) {
  final p = currentProgram(state);
  if (p == null) return '';
  return '${tr(currentDay(state).date, labels)} · ${p.time}';
}

void main() {
  test('ticketWhen', () {
    expect(app.ticketWhen(sample()), 'Sat, Nov 15 · 10:00');
  });
}
