// altInfo: An alternative program's kcal and monthly cost.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/alt_indexes.dart';
import 'shared/group_digits.dart';
import 'shared/money.dart';

String altInfo(State state, Labels labels, int index) {
  final p = state.programs[altIndexes(state)[index].toInt()];
  return '${groupDigits(p.kcal, labels.thousandsSep)} ${labels.kcal} · ${money(p.monthlyCost, labels)}${labels.perMonth}';
}

void main() {
  test('altInfo', () async {
    expect(app.altInfo(sample(goal: Goal.weightLoss, program: 8).copyWith(matches: [8, 9]), 0), r'1,550 kcal · $320/mo');
  });
}
