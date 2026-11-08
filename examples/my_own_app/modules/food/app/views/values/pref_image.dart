// prefImage: A preference card's illustration.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';
import 'shared/image_path.dart';

String prefImage(State state, int index) => imagePath(state.prefs[index].image);

void main() {
  test('prefImage', () async {
    expect(app.prefImage(sample(), 0), endsWith('forkcast_vegan.svg'));
  });
}
