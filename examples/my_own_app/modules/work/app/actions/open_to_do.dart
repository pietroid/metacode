// openToDo: Opens the to-do list.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openToDo(State state, Core core) async {
  core.navigator.push(Routes.toDo);
}

void main() {
  test('openToDo', () async {
    await app.openToDo(sample());
    expect(app.navigation, ['push toDo']);
  });
}
