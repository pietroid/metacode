import 'package:flutter_test/flutter_test.dart';

import '../generated/state.dart';
import 'fixtures.dart';

void main() {
  test('state.yaml loads and is usable', () {
    expect(app.plantTip(app.initialState), 'Water Basil today.');
  });

  test('plants status and tip', () {
    expect(app.plantStatus(sample(), 0), 'Water today');
    expect(app.plantStatus(sample(), 1), 'In 2 days');
    expect(app.plantsText(sample()), '1 plant needs water today');
    expect(app.plantTip(sample()), 'Water Basil today.');
    final done = sample(plants: [Plant(name: 'Fern', everyDays: 5, daysLeft: 1)]);
    expect(app.plantTip(done), 'All done. Next up: Fern tomorrow.');
  });
}
