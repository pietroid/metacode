import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metacode/engine/locale.dart';
import 'package:metacode/engine/state_store.dart';
import 'package:metacode/files/project_files.dart';

void main() {
  test('labels file names map to locales and back', () {
    expect(languageLocale('pt_br'), const Locale('pt', 'BR'));
    expect(languageLocale('en'), const Locale('en'));
    const languages = ['en', 'pt_br'];
    expect(matchLanguage(languages, const Locale('pt', 'BR')), 'pt_br');
    expect(matchLanguage(languages, const Locale('pt', 'PT')), 'pt_br');
    expect(matchLanguage(languages, const Locale('en', 'US')), 'en');
    expect(matchLanguage(languages, const Locale('fr')), isNull);
    expect(matchLanguage(['pt', 'pt_br'], const Locale('pt', 'PT')), 'pt');
  });

  test('the picked language is saved and read back on the next launch',
      () async {
    final files = ProjectFiles();
    final locale = AppLocale(store: FilesStateStore(files));
    await locale.set('pt_br');
    expect(files.read('.state/locale.yaml'), 'locale: pt_br\n');

    final next = AppLocale(store: FilesStateStore(files));
    await next.load();
    expect(next.language, 'pt_br');
    expect(next.locale, const Locale('pt', 'BR'));

    await next.set(null);
    final device = AppLocale(store: FilesStateStore(files));
    await device.load();
    expect(device.locale, isNull);
  });
}
