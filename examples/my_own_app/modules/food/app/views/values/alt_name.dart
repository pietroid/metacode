// altName: An alternative program's name.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/alt_indexes.dart';
import 'shared/pick.dart';

String altName(State state, Labels labels, int index) {
  final p = state.programs[altIndexes(state)[index].toInt()];
  return pick(labels, p.name, p.namePt);
}

void main() {
  test('altName', () async {
    expect(app.altName(sample(goal: Goal.weightLoss, program: 8).copyWith(matches: [8, 9]), 0), 'Sea Breeze Cut');
  });
}
