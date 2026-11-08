// soFarLabel: The cost bar's middle caption: up to and including the selected day.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String soFarLabel(State state, Labels labels) => '${labels.throughDay} ${state.dayIndex.round() + 1}';

void main() {
  test('soFarLabel', () {
    expect(app.soFarLabel(sample(dayIndex: 1)), 'Through day 2');
  });
}
