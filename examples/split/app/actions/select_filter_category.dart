// selectFilterCategory: Index 0 -> filterCategory ''; else the category name
// (food, travel, home, other) at index - 1.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> selectFilterCategory(State state, void Function(StateDelta) emit, int index) async {
  final List<String> names = ['', 'food', 'travel', 'home', 'other'];
  if (index < 0 || index >= names.length) return;
  emit(StateDelta(filterCategory: names[index]));
}

void main() {
  test('selectFilterCategory', () async {
    final s = await app.selectFilterCategory(sample(), 2);
    expect(s.filterCategory, 'travel');
  });
}
