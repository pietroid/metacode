// dateErrorText: Why the date was rejected: not picked yet, or a day the month doesn't have.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String dateErrorText(State state, Labels labels) {
  if (state.birthDay == '' || state.birthMonth == '') return labels.pickADate;
  return labels.dateDoesNotExist;
}

void main() {
  test('dateErrorText', () {
    expect(app.dateErrorText(sample(birthDay: '')), 'Pick your day and month first.');
    expect(app.dateErrorText(sample(birthDay: '31', birthMonth: '2')), "That date doesn't exist. Check the day.");
  });
}
