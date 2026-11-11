import 'package:flutter/material.dart' show ThemeMode;
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

  String? _theme;

  /// The theme picked with `core.theme.set` (`light`, `dark`); null follows
  /// the style (app/views/style/theme.yaml).
  String? get theme => _theme;

  /// For `MaterialApp.themeMode`: null when nothing was picked.
  ThemeMode? get themeMode => switch (_theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => null,
      };

  /// Reads the saved theme (`.state/theme.yaml`).
  Future<void> loadTheme() async {
    final saved = await store?.read(const [], file: 'theme');
    if (saved == null) return;
    final doc = loadYaml(saved);
    final theme = doc is Map ? doc['theme'] : null;
    if (theme is String && theme != _theme) {
      _theme = theme;
      notifyListeners();
    }
  }

  /// Shows the whole app [theme] (`light`, `dark`) from now on; null follows
  /// the style again.
  Future<void> setTheme(String? theme) async {
    if (theme == _theme) return;
    _theme = theme;
    notifyListeners();
    await store?.write(const [], 'theme: ${theme ?? 'null'}\n', file: 'theme');
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
