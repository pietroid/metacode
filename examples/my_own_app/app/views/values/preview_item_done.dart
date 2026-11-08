// previewItemDone: Whether a row of the studio preview app's list is checked
// off (the first two are, to show progress).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool previewItemDone(State state, int index) => index < 2;

void main() {
  test('previewItemDone', () {
    expect(app.previewItemDone(sample(), 0), isTrue);
    expect(app.previewItemDone(sample(), 2), isFalse);
  });
}
