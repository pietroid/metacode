import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('jobs and taxes', () async {
    expect((await app.toggleJobPaid(sample(), 0, true)).jobs[0].paid, isTrue);
    expect((await app.setTaxRate(sample(), 20.4)).taxRate, 20);
  });
}
