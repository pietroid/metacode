// previewItemText: One row of the studio preview app's list (by index).
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'preview_items.dart';

String previewItemText(State state, Labels labels, int index) =>
    previewItems(state, labels)[index];

void main() {
  test('previewItemText', () {
    expect(
      app.previewItemText(sample(appKind: AppKind.plants), 0),
      'Water the fern',
    );
  });
}
