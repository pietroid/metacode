// swatchColor: The palette color of the Swatch at `index`.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../actions/shared/palette.dart';
import '../../models/sample.dart';

String swatchColor(State state, int index) => palette()[index];

void main() {
  test('swatchColor is the palette color', () {
    expect(app.swatchColor(sample(), 0), '#111111');
  });
}
