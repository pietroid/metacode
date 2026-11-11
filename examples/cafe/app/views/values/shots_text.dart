// shotsText: draftShots with shot/shots label.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String shotsText(State state, Labels labels) {
  final int n = state.draftShots.toInt();
  if (n == 1) return '$n ${labels.shot}';
  return '$n ${labels.shots}';
}

void main() {
  test('initial', () {
    expect(app.shotsText(sample()), '0 shots');
  });
  test('one', () {
    expect(app.shotsText(sample({'draftShots': 1})), '1 shot');
  });
}
