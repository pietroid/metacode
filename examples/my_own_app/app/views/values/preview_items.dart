// previewItems: The three rows of the studio preview app's list, by what it
// is about.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<String> previewItems(State state, Labels labels) {
  if (state.appKind == AppKind.plants) {
    return [labels.plantsItem1, labels.plantsItem2, labels.plantsItem3];
  }
  if (state.appKind == AppKind.habits) {
    return [labels.habitsItem1, labels.habitsItem2, labels.habitsItem3];
  }
  if (state.appKind == AppKind.meals) {
    return [labels.mealsItem1, labels.mealsItem2, labels.mealsItem3];
  }
  if (state.appKind == AppKind.bills) {
    return [labels.billsItem1, labels.billsItem2, labels.billsItem3];
  }
  return [labels.customItem1, labels.customItem2, labels.customItem3];
}

void main() {
  test('previewItems', () {
    expect(app.previewItems(sample(appKind: AppKind.plants)).length, 3);
    expect(app.previewItems(sample(appKind: AppKind.meals))[0], 'Lentil soup');
  });
}
