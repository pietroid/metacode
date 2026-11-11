// groupInitials: First letters of group index's first two words, uppercase.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String groupInitials(State state, int index) {
  final List<String> parts = state.groups[index].name.split(' ');
  var s = '';
  for (var i = 0; i < parts.length && i < 2; i++) {
    if (parts[i].isNotEmpty) s += parts[i][0];
  }
  return s.toUpperCase();
}

void main() {
  test('groupInitials', () {
    expect(app.groupInitials(sample(), 0), 'LT');
  });
}
