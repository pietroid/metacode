// showAttractions: Shows only the day's attractions.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> showAttractions(State state, void Function(StateDelta) emit) async =>
    emit(StateDelta(filter: ProgramFilter.attraction));

void main() {
  test('showAttractions', () async {
    final s = await app.showAttractions(sample(filter: ProgramFilter.transport));
    expect(s.filter, ProgramFilter.attraction);
  });
}
