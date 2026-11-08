// dayTotalText: The selected day's whole cost, under the food budget ("This day in total: €65").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/current_day.dart';
import 'shared/day_total.dart';
import 'shared/euros.dart';

String dayTotalText(State state, Labels labels) => '${labels.dayInTotal} ${euros(dayTotal(currentDay(state)), labels)}';

void main() {
  test('dayTotalText', () {
    expect(app.dayTotalText(sample()), 'This day in total: €65');
  });
}
