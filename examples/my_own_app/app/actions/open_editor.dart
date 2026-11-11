// openEditor: Opens the editor module's page (editor.mainRoute) over the site.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> openEditor(State state, Core core) async {
  await core.modules.editor.navigator.push(EditorRoutes.mainRoute);
}

void main() {
  test('openEditor opens editor.mainRoute', () async {
    await app.openEditor(sample());
    expect(app.navigation, ['push editor.mainRoute']);
  });
}
