// openConsult: Opens the consultation booking sheet.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openConsult(State state, Core core) async {
  core.navigator.push(Routes.consult);
}

void main() {
  test('openConsult', () async {
    await app.openConsult(sample());
    expect(app.navigation, ['push consult']);
  });
}
