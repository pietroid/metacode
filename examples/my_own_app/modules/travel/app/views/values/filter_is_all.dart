// filterIsAll: Whether the day shows every plan.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool filterIsAll(State state) => state.filter == ProgramFilter.all;

void main() {
  test('filterIsAll', () {
    expect(app.filterIsAll(sample()), isTrue);
  });
}
