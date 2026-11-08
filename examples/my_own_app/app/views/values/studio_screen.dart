// studioScreen: What the studio phone shows: empty (nothing made yet),
// making (the build is running), updating (a tweak is landing) or ready.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String studioScreen(State state) {
  if (state.tweaking) return 'updating';
  if (state.buildStep >= 5) return 'ready';
  if (state.buildStep >= 1) return 'making';
  return 'empty';
}

void main() {
  test('studioScreen', () {
    expect(app.studioScreen(sample()), 'empty');
    expect(app.studioScreen(sample(buildStep: 2)), 'making');
    expect(app.studioScreen(sample(buildStep: 5)), 'ready');
    expect(app.studioScreen(sample(buildStep: 5, tweaking: true)), 'updating');
  });
}
