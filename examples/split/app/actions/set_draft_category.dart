// setDraftCategory: Sets draftCategory from its name (food, travel, home,
// other).

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setDraftCategory(State state, void Function(StateDelta) emit, String value) async {
  var c = Category.other;
  if (value == 'food') c = Category.food;
  if (value == 'travel') c = Category.travel;
  if (value == 'home') c = Category.home;
  emit(StateDelta(draftCategory: c));
}

void main() {
  test('setDraftCategory', () async {
    final s = await app.setDraftCategory(sample(), 'travel');
    expect(s.draftCategory, Category.travel);
  });
}
