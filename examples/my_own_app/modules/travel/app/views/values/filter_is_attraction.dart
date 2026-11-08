// filterIsAttraction: Whether the day shows only attractions.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool filterIsAttraction(State state) => state.filter == ProgramFilter.attraction;

void main() {
  test('filterIsAttraction', () {
    expect(app.filterIsAttraction(sample()), isFalse);
  });
}
