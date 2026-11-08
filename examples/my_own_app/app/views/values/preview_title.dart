// previewTitle: The studio preview app's title, by what it is about.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String previewTitle(State state, Labels labels) {
  if (state.appKind == AppKind.plants) return labels.myPlants;
  if (state.appKind == AppKind.habits) return labels.myHabits;
  if (state.appKind == AppKind.meals) return labels.thisWeeksMeals;
  if (state.appKind == AppKind.bills) return labels.ourBills;
  return labels.myApp;
}

void main() {
  test('previewTitle', () {
    expect(app.previewTitle(sample(appKind: AppKind.plants)), 'My plants');
    expect(app.previewTitle(sample()), 'My app');
  });
}
