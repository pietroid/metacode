// Validates app/views/ (pages and components) against the widget catalog
// (packages/app_ui/lib/spec.dart) and the app's names, and records what each
// widget references for the index (lib/compiler/index.dart).

import 'package:app_ui/spec.dart';

import 'issues.dart';

/// What one page or component references, by name. Filled while validating;
/// the index (`.generated/INDEX.md`) prints it and its reverse ("used by").
class WidgetRefs {
  final widgets = <String>{}; // pages/components it embeds
  final values = <String>{};
  final actions = <String>{};
  final labels = <String>{};
  final modules = <String>{};
}

/// Validates app/views/ widgets (pages and components) against the widget catalog,
/// the values, the labels, the actions and the modules. [widgets] maps each widget id to its
/// definition; [fileOf] maps each id back to the file that declared it.
///
/// Returns every widget by id (empty on errors in the file shapes). When
/// [refs] is given, it is filled with what each widget references.
Map<String, dynamic> validateWidgets(
  Map<String, dynamic> widgets,
  Map<String, String> fileOf,
  Set<String> bindings,
  Set<String> labels,
  Set<String> actions,
  Set<String> modules,
  Issues issues, {
  bool requireMainPage = true, // false when app/views/navigation.yaml names the pages
  Map<String, WidgetRefs>? refs,
}) {
  if (requireMainPage && !widgets.containsKey('MainPage')) {
    issues.error('app/views/pages/main_page.yaml', '',
        'missing "MainPage", the entry page (or add app/views/navigation.yaml)');
  }
  for (final id in widgets.keys) {
    if (bindings.contains(id) || actions.contains(id)) {
      issues.error(fileOf[id]!, id,
          'widget id is also the name of a ${bindings.contains(id) ? 'value' : 'action'}');
    }
  }

  for (final entry in widgets.entries) {
    final found = WidgetRefs();
    refs?[entry.key] = found;
    _UiValidator(fileOf[entry.key]!, widgets, bindings, labels, actions, modules,
            issues, found)
        .node(entry.value, entry.key);
  }
  return widgets;
}

class _UiValidator {
  final String file;
  final Map<String, dynamic> widgets;
  final Set<String> bindings;
  final Set<String> labels;
  final Set<String> actions;
  final Set<String> modules;
  final Issues issues;
  final WidgetRefs refs;

  _UiValidator(this.file, this.widgets, this.bindings, this.labels,
      this.actions, this.modules, this.issues, this.refs);

  /// Props that show text: a value, a label or (discouraged) literal text.
  static const _textProps = {'hint', 'label', 'tooltip'};

  void error(String path, String message) =>
      issues.error(file, path, message);

  void node(dynamic value, String path) {
    if (value == null) return;
    if (value is String) {
      if (pascalCase.hasMatch(value) && !widgets.containsKey(value)) {
        return error(path, '"$value" is not a page or component in app/views/ '
            '(text belongs in app/views/labels/)');
      }
      if (widgets.containsKey(value)) {
        refs.widgets.add(value);
      } else {
        text(value, path);
      }
      return;
    }
    if (value is num || value is bool) return;
    if (value is! Map) return error(path, 'expected a widget');
    if (value.length != 1) {
      return error(path,
          'a widget is a single key (its type), got ${value.keys.join(', ')}');
    }

    final type = value.keys.first.toString();
    final spec = widgetCatalog[type];
    if (spec == null) {
      return error('$path.$type',
          'unknown widget "$type"; available: ${widgetCatalog.keys.join(', ')}');
    }
    widget(spec, value[type], '$path.$type');
  }

  void widget(WidgetSpec spec, dynamic value, String path) {
    final props = normalizeProps(spec, value);
    if (props == null) {
      return error(path, 'expected a map of properties'
          '${spec.shorthand.prop == null ? '' : ' or a ${spec.shorthand.prop}'}');
    }
    for (final entry in props.entries) {
      final prop = entry.key.toString();
      final kind = spec.props[prop];
      final propPath = '$path.$prop';
      if (kind == null) {
        error(propPath,
            'unknown property; available: ${spec.props.keys.join(', ')}');
        continue;
      }
      property(kind, entry.value, propPath, spec.inline[prop]);
      final isText = _textProps.contains(prop) ||
          (identical(spec, widgetCatalog['text']) && prop == 'value');
      if (isText && entry.value is String) text(entry.value, propPath);
    }
  }

  void property(PropKind kind, dynamic value, String path, String? inline) {
    switch (kind) {
      case PropKind.node:
        node(value, path);
      case PropKind.nodes:
        if (value is! List) return error(path, 'expected a list of widgets');
        nodes(value, path);
      case PropKind.action:
        if (actions.contains(value)) refs.actions.add(value);
        if (!actions.contains(value)) {
          error(path, '"$value" is not an action; '
              'available: ${actions.isEmpty ? '(none)' : actions.join(', ')}');
        }
      case PropKind.binding:
        if (bindings.contains(value)) refs.values.add(value);
        if (!bindings.contains(value)) {
          error(path, '"$value" is not a value (app/views/values/); '
              'available: ${bindings.isEmpty ? '(none)' : bindings.join(', ')}');
        }
      case PropKind.module:
        if (modules.contains(value)) refs.modules.add(value);
        if (!modules.contains(value)) {
          error(path, '"$value" is not a module (a folder in modules/); '
              'available: ${modules.isEmpty ? '(none)' : modules.join(', ')}');
        }
      case PropKind.inline:
        widget(widgetCatalog[inline]!, value, path);
      case PropKind.nodeMap:
        if (value is! Map) return error(path, 'expected a map of value: node');
        for (final entry in value.entries) {
          node(entry.value, '$path.${entry.key}');
        }
      case PropKind.icon:
        if (!iconNames.contains(value)) {
          error(path, 'unknown icon "$value"; see Icons in REFERENCE.md');
        }
      case PropKind.color:
        if (!isColor(value)) {
          error(path, 'unknown color "$value"; use #RRGGBB or a name from '
              'Colors in REFERENCE.md');
        }
      case PropKind.bindingOrLiteral:
      case PropKind.literal:
        _recordNames(value);
    }
  }

  /// Records the values and labels a literal names: a bare string, or the
  /// strings and `value:` entries of a list (text `spans`). Other map keys
  /// (`style:` and so on) are skipped: they hold variants, not names.
  void _recordNames(dynamic value) {
    if (value is String) {
      if (bindings.contains(value)) refs.values.add(value);
      if (labels.contains(value)) refs.labels.add(value);
    } else if (value is List) {
      value.forEach(_recordNames);
    } else if (value is Map) {
      _recordNames(value['value']);
    }
  }

  /// A string shown as text: a value, a label, or literal text (which
  /// belongs in app/views/labels/).
  void text(String value, String path) {
    if (bindings.contains(value)) refs.values.add(value);
    if (labels.contains(value)) refs.labels.add(value);
    if (bindings.contains(value) || labels.contains(value)) return;
    if (camelCase.hasMatch(value)) {
      issues.warn(file, path, '"$value" is not a value or label; '
          'it will show as literal text');
    } else if (RegExp(r'[A-Za-z]').hasMatch(value)) {
      issues.warn(file, path,
          'literal text; move it to app/views/labels/ and use its key');
    }
  }

  void nodes(List value, String path) {
    for (var i = 0; i < value.length; i++) {
      node(value[i], '$path[$i]');
    }
  }
}
