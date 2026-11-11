// hasRedeemed: whether a reward was redeemed (lastRedeemed not empty).

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool hasRedeemed(State state) => state.lastRedeemed.isNotEmpty;

void main() {
  test('hasRedeemed', () {
    expect(app.hasRedeemed(sample()), false);
  });
  test('hasRedeemed set', () {
    expect(app.hasRedeemed(sample({'lastRedeemed': 'Free drink'})), true);
  });
}
