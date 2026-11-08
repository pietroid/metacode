// mapSubtitle: The birth date and its week under the map title ("Born 12 August · week 2 of the month").
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/birth_numbers.dart';
import 'shared/month_name.dart';
import 'shared/week_of_month.dart';

String mapSubtitle(State state, Labels labels) {
  final date = birthNumbers(state);
  final week = weekOfMonth(state) + 1;
  return '${labels.born} ${date.$1} ${monthName(date.$2, labels)} · ${labels.week} $week ${labels.ofTheMonth}';
}

void main() {
  test('mapSubtitle', () {
    expect(app.mapSubtitle(sample()), 'Born 12 August · week 2 of the month');
  });
}
