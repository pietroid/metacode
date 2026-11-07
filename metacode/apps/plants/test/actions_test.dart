import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('plants: water resets, next day counts down', () async {
    expect((await app.waterPlant(sample(), 0)).plants[0].daysLeft, 3);
    final s = await app.nextDay(sample());
    expect([s.plants[0].daysLeft, s.plants[1].daysLeft], [0, 1]);
  });
}
