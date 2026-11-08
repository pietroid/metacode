// visibleProgramList: The selected day's plans that pass the filter.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/visible_programs.dart';

List<Program> visibleProgramList(State state) => visiblePrograms(state);

void main() {
  test('visibleProgramList', () {
    expect(app.visibleProgramList(sample(filter: ProgramFilter.attraction)).length, 2);
  });
}
