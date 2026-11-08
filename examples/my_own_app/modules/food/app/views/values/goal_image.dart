// goalImage: A goal card's illustration.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/image_path.dart';

String goalImage(State state, int index) => imagePath(state.goalOptions[index].image);

void main() {
  test('goalImage', () async {
    expect(app.goalImage(sample(), 0), endsWith('forkcast_low_carb.svg'));
  });
}
