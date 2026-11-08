// ticketShare: The open plan's part of its day ("of €65 this day").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_day.dart';
import 'shared/day_total.dart';
import 'shared/euros.dart';

String ticketShare(State state, Labels labels) => '${labels.ofDay} ${euros(dayTotal(currentDay(state)), labels)} ${labels.thisDayLower}';

void main() {
  test('ticketShare', () {
    expect(app.ticketShare(sample()), 'of €65 this day');
  });
}
