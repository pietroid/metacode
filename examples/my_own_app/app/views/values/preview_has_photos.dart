// previewHasPhotos: Whether the studio preview app shows a photo.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

bool previewHasPhotos(State state) => state.appPhotos;

void main() {
  test('previewHasPhotos', () {
    expect(app.previewHasPhotos(sample(appPhotos: true)), isTrue);
  });
}
