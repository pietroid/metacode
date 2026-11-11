// starsToGoText: stars left to the next free drink, or a ready message.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String starsToGoText(State state, Labels labels) {
  final int stars = state.stars.toInt();
  if (stars >= 150) return labels.freeDrinkReady;
  return '${150 - stars} ${labels.toFreeDrink}';
}

void main() {
  test('starsToGoText', () {
    expect(app.starsToGoText(sample()), '38 stars to your next free drink');
  });
  test('starsToGoText ready', () {
    expect(app.starsToGoText(sample({'stars': 150})), 'You have a free drink waiting!');
  });
}
