// astrologyEnabled: Whether the astrology example is on (the config.astrology
// feature toggle): CarouselNav shows its chip only then.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool astrologyEnabled(State state) {
  return state.config.astrology;
}

void main() {
  test('astrologyEnabled follows the toggle', () {
    expect(app.astrologyEnabled(sample(astrology: true)), true);
    expect(app.astrologyEnabled(sample(astrology: false)), false);
  });
}
