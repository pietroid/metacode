// dayDateCity: The selected day's date and city ("Wed, Jun 2 · Lisbon").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_day.dart';
import 'shared/tr.dart';

String dayDateCity(State state, Labels labels) {
  final d = currentDay(state);
  return '${tr(d.date, labels)} · ${tr(d.city, labels)}';
}

void main() {
  test('dayDateCity', () {
    expect(app.dayDateCity(sample()), 'Sat, Nov 15 · Sintra');
    app.locale = 'pt_br';
    expect(app.dayDateCity(sample()), 'Sáb, 15 de nov · Sintra');
    app.locale = null;
  });
}
