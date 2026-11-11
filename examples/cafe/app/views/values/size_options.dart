// sizeOptions: The three drink sizes.

import 'package:flutter_test/flutter_test.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<DrinkSize> sizeOptions(State state) {
  return [DrinkSize.small, DrinkSize.medium, DrinkSize.large];
}

void main() {
  test('3 sizes', () {
    expect(app.sizeOptions(sample()).length, 3);
  });
}
