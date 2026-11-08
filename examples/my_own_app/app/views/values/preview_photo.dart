// previewPhoto: The photo the studio preview app shows once photos are on,
// by what it is about.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

String previewPhoto(State state) {
  if (state.appKind == AppKind.plants) {
    return 'examples/my_own_app/app/views/style/images/plant.jpg';
  }
  if (state.appKind == AppKind.meals) {
    return 'examples/my_own_app/app/views/style/images/food.jpg';
  }
  if (state.appKind == AppKind.habits) {
    return 'examples/my_own_app/app/views/style/images/guitar.jpg';
  }
  return 'examples/my_own_app/app/views/style/images/desk.jpg';
}

void main() {
  test('previewPhoto', () {
    expect(app.previewPhoto(sample(appKind: AppKind.meals)), contains('food'));
  });
}
