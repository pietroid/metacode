import 'package:app_ui/spec.dart';

import 'issues.dart';

/// Validates ui.yaml against the widget catalog, the bindings and the actions.
void validateUi(
  dynamic doc,
  Set<String> bindings,
  Set<String> actions,
  Issues issues, {
  bool requireHomePage = true, // false when navigation.yaml names the pages
}) {
  const file = 'ui.yaml';
  if (doc is! Map || doc['widgets'] is! Map) {
    issues.error(file, '', 'must contain a top-level "widgets:" map');
    return;
  }
  final widgets = Map<String, dynamic>.from(doc['widgets'] as Map);

  if (requireHomePage && !widgets.containsKey('homePage')) {
    issues.error(file, 'widgets', 'missing "homePage", the entry widget');
  }
  for (final id in widgets.keys) {
    if (bindings.contains(id) || actions.contains(id)) {
      issues.error(file, 'widgets.$id',
          'widget id is also the name of a ${bindings.contains(id) ? 'binding' : 'action'}');
    }
  }

  final v = _UiValidator(widgets, bindings, actions, issues);
  for (final entry in widgets.entries) {
    v.node(entry.value, 'widgets.${entry.key}');
  }
}

class _UiValidator {
  final Map<String, dynamic> widgets;
  final Set<String> bindings;
  final Set<String> actions;
  final Issues issues;

  _UiValidator(this.widgets, this.bindings, this.actions, this.issues);

  static final _looksLikeName = RegExp(r'^[a-z][a-zA-Z0-9]*$');

  void error(String path, String message) =>
      issues.error('ui.yaml', path, message);

  void node(dynamic value, String path) {
    if (value == null) return;
    if (value is String) {
      if (_looksLikeName.hasMatch(value) &&
          !widgets.containsKey(value) &&
          !bindings.contains(value)) {
        issues.warn('ui.yaml', path,
            '"$value" is not a widget or binding; it will show as literal text');
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
        if (!actions.contains(value)) {
          error(path, '"$value" is not an action; '
              'available: ${actions.isEmpty ? '(none)' : actions.join(', ')}');
        }
      case PropKind.binding:
        if (!bindings.contains(value)) {
          error(path, '"$value" is not a binding; '
              'available: ${bindings.isEmpty ? '(none)' : bindings.join(', ')}');
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
        break;
    }
  }

  void nodes(List value, String path) {
    for (var i = 0; i < value.length; i++) {
      node(value[i], '$path[$i]');
    }
  }
}
