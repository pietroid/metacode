// categoryValue: draftCategory's name.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String categoryValue(State state) {
  if (state.draftCategory == Category.travel) return 'travel';
  if (state.draftCategory == Category.home) return 'home';
  if (state.draftCategory == Category.other) return 'other';
  return 'food';
}

void main() {
  test('categoryValue', () {
    expect(app.categoryValue(sample()), 'food');
    expect(app.categoryValue(sample({'draftCategory': 'home'})), 'home');
  });
}
