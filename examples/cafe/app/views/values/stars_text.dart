// starsText: the stars balance as text.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String starsText(State state) => '${state.stars.toInt()}';

void main() {
  test('starsText', () {
    expect(app.starsText(sample()), '112');
  });
  test('starsText zero', () {
    expect(app.starsText(sample({'stars': 0})), '0');
  });
}
