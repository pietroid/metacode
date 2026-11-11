// rewardStarsText: stars cost of reward index as text.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String rewardStarsText(State state, Labels labels, int index) {
  if (index < 0 || index >= state.rewards.length) return '';
  return '${state.rewards[index].stars.toInt()} ${labels.starsWord}';
}

void main() {
  test('rewardStarsText', () {
    expect(app.rewardStarsText(sample(), 2), '150 stars');
  });
  test('rewardStarsText out of range', () {
    expect(app.rewardStarsText(sample(), 9), '');
  });
}
