import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('state.yaml loads and is usable', () {
    expect(app.receivedText(app.initialState), '\$1,550');
  });

  test('work totals, taxes and tip', () {
    expect(app.receivedText(sample()), '\$1,200');
    expect(app.waitingText(sample()), '\$800');
    expect(app.taxText(sample()), 'Set aside 10% for taxes: \$120');
    expect(app.workTip(sample()), contains('Bakery still owes you \$800'));
    expect(app.jobAmount(sample(), 1), '\$1,200');
  });
}
