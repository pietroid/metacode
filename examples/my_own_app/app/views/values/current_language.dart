// currentLanguage: The language the site is shown in (a labels file name:
// en, pt_br), for the LanguagePicker.
import 'package:flutter_test/flutter_test.dart';

import '../../../.generated/labels.dart';
import '../../../.generated/state.dart';
import '../../models/sample.dart';

String currentLanguage(State state, Labels labels) => labels.locale;

void main() {
  test('currentLanguage is the language the labels are in', () {
    expect(app.currentLanguage(sample()), 'en');
    app.locale = 'pt_br';
    expect(app.currentLanguage(sample()), 'pt_br');
    app.locale = null;
  });
}
