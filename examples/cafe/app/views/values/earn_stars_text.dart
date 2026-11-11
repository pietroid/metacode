// earnStarsText: 'You'll earn 13 stars' - floor(subtotal).

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/line_price.dart';

String earnStarsText(State state, Labels labels) {
  num total = 0;
  for (final CartLine l in state.cart) {
    total += linePrice(state.menu, l);
  }
  return '${labels.youllEarn} ${total.floor()} ${labels.starsWord}';
}

void main() {
  test('initial', () {
    expect(app.earnStarsText(sample()), "You'll earn 13 stars");
  });
}
