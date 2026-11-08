// tripCover: A trip's cover photo (an image path).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String tripCover(State state, int index) => state.trips[index].cover;

void main() {
  test('tripCover', () {
    expect(app.tripCover(sample(), 0), 'cover.jpg');
  });
}
