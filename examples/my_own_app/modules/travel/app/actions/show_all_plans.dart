// showAllPlans: Shows every plan of the day.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showAllPlans(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(filter: ProgramFilter.all));

void main() {
  test('showAllPlans', () async {
    final s = await app.showAllPlans(sample(filter: ProgramFilter.transport));
    expect(s.filter, ProgramFilter.all);
  });
}
