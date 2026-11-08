import 'package:flutter/widgets.dart';
import 'package:yaml/yaml.dart';

import 'state_store.dart';

/// Languages are named after their labels file (app/views/labels/): `en`,
/// `pt`, `pt_br`. Flutter's localization resolves the device's locales
/// against the root app's languages (`MaterialApp.supportedLocales`); each
/// app then shows its labels file that best fits the resolved locale
/// ([matchLanguage]).

/// `pt_br` -> `Locale('pt', 'BR')`.
Locale languageLocale(String language) {
  final parts = language.split('_');
  return Locale(parts[0], parts.length > 1 ? parts[1].toUpperCase() : null);
}

/// The one of [languages] that best fits [locale]: the same language and
/// region, else the language alone (`pt`), else any region of it; null if
/// none speaks it.
String? matchLanguage(Iterable<String> languages, Locale locale) {
  final lang = locale.languageCode.toLowerCase();
  final region = locale.countryCode?.toLowerCase();
  if (region != null && languages.contains('${lang}_$region')) {
    return '${lang}_$region';
  }
  if (languages.contains(lang)) return lang;
  for (final l in languages) {
    if (l.startsWith('${lang}_')) return l;
  }
  return null;
}

/// The language the user picked for the whole app (`core.locale.set`), or
/// null to follow the device. Saved in the root's `.state/locale.yaml`
/// (`locale: pt_br`) when there is a [store].
class AppLocale extends ChangeNotifier {
  final StateStore? store;

  AppLocale({this.store});

  String? _language;

  /// The picked labels file name (`pt_br`); null follows the device.
  String? get language => _language;

  /// For `MaterialApp.locale`: null lets Flutter pick from the device.
  Locale? get locale => _language == null ? null : languageLocale(_language!);

  /// Reads the saved language.
  Future<void> load() async {
    final saved = await store?.read(const [], file: 'locale');
    if (saved == null) return;
    final doc = loadYaml(saved);
    final language = doc is Map ? doc['locale'] : null;
    if (language is String && language != _language) {
      _language = language;
      notifyListeners();
    }
  }

  /// Shows [language] from now on; null follows the device again.
  Future<void> set(String? language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    await store?.write(const [], 'locale: ${language ?? 'null'}\n',
        file: 'locale');
  }
}
