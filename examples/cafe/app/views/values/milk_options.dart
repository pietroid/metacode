// milkOptions: The four milks.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Milk> milkOptions(State state) {
  return [Milk.whole, Milk.oat, Milk.almond, Milk.none];
}

void main() {
  test('4 milks', () {
    expect(app.milkOptions(sample()).length, 4);
  });
}
