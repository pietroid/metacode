// tripDates: A trip's dates.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/tr.dart';

String tripDates(State state, Labels labels, int index) => tr(state.trips[index].dates, labels);

void main() {
  test('tripDates', () {
    expect(app.tripDates(sample(), 0), 'Nov 15 – 16');
    app.locale = 'pt_br';
    expect(app.tripDates(sample(), 0), '15 a 16 de nov');
    app.locale = null;
  });
}
