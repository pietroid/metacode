// prefSelected: Whether a preference card is selected.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool prefSelected(State state, int index) => state.prefs[index].selected;

void main() {
  test('prefSelected', () async {
    expect(app.prefSelected(sample(prefs: ['vegan']), 0), true);
  });
}
