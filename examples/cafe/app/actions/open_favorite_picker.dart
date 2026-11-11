// openFavoritePicker: pushes the favoritePicker dialog.

import 'package:flutter_test/flutter_test.dart';
import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openFavoritePicker(State state, Core core) async {
  core.navigator.push(Routes.favoritePicker);
}

void main() {
  test('openFavoritePicker', () async {
    await app.openFavoritePicker(sample());
    expect(app.navigation, ['push favoritePicker']);
  });
}
