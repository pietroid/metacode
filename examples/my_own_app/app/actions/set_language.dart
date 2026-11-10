// setLanguage: Shows the whole site (modules too) in the language picked in
// the LanguagePicker, from now on.
import 'package:flutter_test/flutter_test.dart';

import '../../.generated/core.dart';
import '../../.generated/state.dart';
import '../models/sample.dart';

Future<void> setLanguage(State state, Core core, String value) async {
  await core.locale.set(value);
}

void main() {
  test('setLanguage switches the labels', () async {
    addTearDown(() => app.locale = null);
    await app.setLanguage(sample(), 'pt_br');
    expect(app.locale, 'pt_br');
    expect(app.joinedText(sample(waitlistEmail: 'a@b.co')),
        'Vamos avisar a@b.co quando sua vaga abrir.');
  });
}
