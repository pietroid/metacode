// altPrograms: The other programs that match the answers, to switch to.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/alt_indexes.dart';

List<Program> altPrograms(State state) {
  final out = <Program>[];
  for (final i in altIndexes(state)) {
    out.add(state.programs[i.toInt()]);
  }
  return out;
}

void main() {
  test('altPrograms', () async {
    expect(app.altPrograms(sample(goal: Goal.weightLoss, program: 8).copyWith(matches: [8, 9, 10])).length, 2);
  });
}
