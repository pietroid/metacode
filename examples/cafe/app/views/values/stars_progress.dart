// starsProgress: progress to the next free drink: (stars % 150) / 150, or 1 from 150 stars.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

num starsProgress(State state) {
  final int stars = state.stars.toInt();
  if (stars >= 150) return 1;
  return (stars % 150) / 150;
}

void main() {
  test('starsProgress', () {
    expect(app.starsProgress(sample()), closeTo(112 / 150, 0.001));
  });
  test('starsProgress full', () {
    expect(app.starsProgress(sample({'stars': 200})), 1);
  });
}
