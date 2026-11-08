// daysText: How many days the next recipe suggestions cover.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String daysText(State state, Labels labels) => '${state.days} ${labels.days}';

void main() {
  test('daysText', () async {
    expect(app.daysText(sample()), '5 days');
  });
}
