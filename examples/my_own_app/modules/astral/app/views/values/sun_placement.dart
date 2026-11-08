// sunPlacement: The sun sign, from the birth date.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/placement_name.dart';

String sunPlacement(State state, Labels labels) => placementName(state, 0, labels);

void main() {
  test('sunPlacement', () {
    expect(app.sunPlacement(sample()), 'Leo');
  });
}
