// followUpPerson: Who a follow-up is waiting on.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String followUpPerson(State state, int index) => state.followUps[index].person;

void main() {
  test('followUpPerson', () {
    expect(app.followUpPerson(sample(), 0), 'Tom');
  });
}
