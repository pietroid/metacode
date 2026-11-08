// prefList: The food preference cards shown in the prefs grid.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/state.dart';
import '../../models/sample.dart';

List<Pref> prefList(State state) => state.prefs;

void main() {
  test('prefList', () async {
    expect(app.prefList(sample()).length, 6);
  });
}
