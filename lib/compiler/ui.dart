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

  /// Its parameters (`.screen`), inferred from where it uses them, with the
  /// kinds of the props they fill. All are required where it is called.
  final params = <String, Set<PropKind>>{};
}

/// What a host app can use of one of its modules, as `<module>.<name>`:
/// `food.MenuCard` (a component or page), `food.addItem` (an action),
/// `food.total` (a value), `food.title` (a label).
class ModuleNames {
  /// Pages and components, with each one's parameters (and the kinds of
  /// the props they fill).
  final Map<String, Map<String, Set<PropKind>>> widgets;
  final Set<String> pages;
  final Set<String> bindings;
  final Set<String> actions;
  final Set<String> labels;

  const ModuleNames({
    this.widgets = const {},
    this.pages = const {},
    this.bindings = const {},
    this.actions = const {},
    this.labels = const {},
  });
}

/// `food.addItem` -> (`food`, `addItem`): a module name, a dot, a name.
final qualifiedName = RegExp(r'^([a-z][a-zA-Z0-9]*)\.([A-Za-z][a-zA-Z0-9]*)$');

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
  Map<String, ModuleNames> modules,
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

  // Parameters are inferred from where they are used; one passed on to
  // another component (`PhoneStatusBar: {color: .ink}`) takes that one's
  // kinds, so this repeats until nothing new is found. Issues are kept only
  // from the last pass.
  final params = {for (final id in widgets.keys) id: <String, Set<PropKind>>{}};
  String snapshot() => [
        for (final MapEntry(key: id, value: p) in params.entries)
          for (final MapEntry(key: name, value: kinds) in p.entries)
            '$id.$name:${kinds.map((k) => k.name).join(',')}',
      ].join(' ');
  for (var i = 0; i <= widgets.length; i++) {
    final before = snapshot();
    for (final entry in widgets.entries) {
      _UiValidator(fileOf[entry.key]!, widgets, bindings, labels, actions,
              modules, Issues(), WidgetRefs(), params, entry.key)
          .node(entry.value, entry.key);
    }
    if (snapshot() == before) break;
  }

  for (final entry in widgets.entries) {
    final found = WidgetRefs()..params.addAll(params[entry.key]!);
    refs?[entry.key] = found;
    _UiValidator(fileOf[entry.key]!, widgets, bindings, labels, actions, modules,
            issues, found, params, entry.key)
        .node(entry.value, entry.key);
    final own = params[entry.key]!;
    if (own.isNotEmpty && fileOf[entry.key]!.startsWith('app/views/pages/')) {
      issues.error(fileOf[entry.key]!, entry.key,
          'a page has no parameters (${own.keys.map((p) => '.$p').join(', ')}); '
          'move them to a component');
    }
  }
  return widgets;
}

class _UiValidator {
  final String file;
  final Map<String, dynamic> widgets;
  final Set<String> bindings;
  final Set<String> labels;
  final Set<String> actions;
  final Map<String, ModuleNames> modules;
  final Issues issues;
  final WidgetRefs refs;

  /// Every widget's parameters by name, with the kinds they fill.
  final Map<String, Map<String, Set<PropKind>>> params;

  /// The widget being validated.
  final String self;

  _UiValidator(this.file, this.widgets, this.bindings, this.labels,
      this.actions, this.modules, this.issues, this.refs, this.params,
      this.self);

  /// The module and name of `food.addItem`, when `food` is a module.
  (ModuleNames, String)? _qualified(dynamic value) {
    if (value is! String) return null;
    final m = qualifiedName.firstMatch(value);
    if (m == null) return null;
    final module = modules[m.group(1)];
    return module == null ? null : (module, m.group(2)!);
  }

  bool isBinding(dynamic v) =>
      bindings.contains(v) || (_qualified(v)?.$1.bindings.contains(_qualified(v)!.$2) ?? false);
  bool isAction(dynamic v) =>
      actions.contains(v) || (_qualified(v)?.$1.actions.contains(_qualified(v)!.$2) ?? false);
  bool isLabel(dynamic v) =>
      labels.contains(v) || (_qualified(v)?.$1.labels.contains(_qualified(v)!.$2) ?? false);

  /// The parameters of `food.MenuCard`, when it is a module's page or
  /// component.
  Map<String, Set<PropKind>>? moduleWidget(dynamic v) {
    final q = _qualified(v);
    return q?.$1.widgets[q.$2];
  }

  /// A validator for what a module's component is given: names resolve in
  /// the module; parameters of the calling widget are still recorded.
  _UiValidator _inModule(ModuleNames module, String id) => _UiValidator(
      file,
      {for (final w in module.widgets.keys) w: null},
      module.bindings,
      module.labels,
      module.actions,
      const {},
      issues,
      WidgetRefs(),
      {...module.widgets, self: params[self]!},
      self);

  /// Records [value] as a parameter of [self] filling a [kind] prop, if it
  /// is one (`.screen`).
  bool _param(dynamic value, PropKind kind) {
    final name = paramName(value);
    if (name == null) return false;
    // An inline prop's widget is not kept with the kind: checked as a literal.
    params[self]!
        .putIfAbsent(name, () => {})
        .add(kind == PropKind.inline ? PropKind.literal : kind);
    return true;
  }

  /// Records the parameters anywhere inside a literal (`style: {color: .ink}`).
  void _literalParams(dynamic value) {
    if (_param(value, PropKind.literal)) return;
    if (value is Map) value.values.forEach(_literalParams);
    if (value is List) value.forEach(_literalParams);
  }

  /// A component called with arguments: `PhoneFrame: {screen: surface}`.
  void call(String id, dynamic args, String path) {
    refs.widgets.add(id);
    final declared = params[id]!;
    if (args is! Map) {
      return error(path, 'expected a map of arguments: '
          '${declared.keys.map((p) => '$p: ...').join(', ')}');
    }
    for (final entry in args.entries) {
      final name = entry.key.toString();
      final kinds = declared[name];
      // `index: 0`: the component's values and actions get it as their
      // `index` param, as a list item's do.
      if (kinds == null && name == 'index') {
        if (entry.value is! int) error('$path.index', 'index is an int');
        continue;
      }
      if (kinds == null) {
        error('$path.$name', '$id has no .$name; its parameters: '
            '${declared.isEmpty ? '(none)' : declared.keys.map((p) => '.$p').join(', ')}');
        continue;
      }
      for (final kind in kinds) {
        property(kind, entry.value, '$path.$name', null);
      }
    }
    final missing = declared.keys.where((p) => !args.containsKey(p));
    if (missing.isNotEmpty) {
      error(path, 'missing ${missing.map((p) => '$p:').join(', ')} '
          '($id uses ${missing.map((p) => '.$p').join(', ')})');
    }
  }

  /// Props that show text: a value, a label or (discouraged) literal text.
  static const _textProps = {'hint', 'label', 'tooltip'};

  void error(String path, String message) =>
      issues.error(file, path, message);

  void node(dynamic value, String path) {
    if (value == null) return;
    if (_param(value, PropKind.node)) return;
    if (value is String) {
      final moduleParams = moduleWidget(value);
      if (moduleParams != null) {
        refs.widgets.add(value);
        if (moduleParams.isNotEmpty) {
          error(path, '$value needs arguments: '
              '$value: {${moduleParams.keys.map((p) => '$p: ...').join(', ')}}');
        }
        return;
      }
      final q = _qualified(value);
      if (q != null &&
          !q.$1.bindings.contains(q.$2) &&
          !q.$1.labels.contains(q.$2)) {
        return error(path, '"${q.$2}" is not a page, component, value or '
            'label of the module "${value.split('.').first}"');
      }
      if (pascalCase.hasMatch(value) && !widgets.containsKey(value)) {
        return error(path, '"$value" is not a page or component in app/views/ '
            '(text belongs in app/views/labels/)');
      }
      if (widgets.containsKey(value)) {
        refs.widgets.add(value);
        final declared = params[value]!;
        if (declared.isNotEmpty) {
          error(path, '$value needs arguments: '
              '$value: {${declared.keys.map((p) => '$p: ...').join(', ')}}');
        }
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
    if (widgets.containsKey(type)) return call(type, value[type], '$path.$type');
    final q = _qualified(type);
    if (q != null && q.$1.widgets.containsKey(q.$2)) {
      refs.widgets.add(type);
      return _inModule(q.$1, q.$2).call(q.$2, value[type], '$path.$type');
    }
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
    if (identical(spec, widgetCatalog['miniApp']) &&
        (props.containsKey('module') == props.containsKey('project'))) {
      error(path, 'give either module: (a folder in modules/) or project: '
          '(a value returning a metacodeProject)');
    }
  }

  void property(PropKind kind, dynamic value, String path, String? inline) {
    if (_param(value, kind)) return;
    switch (kind) {
      case PropKind.node:
        node(value, path);
      case PropKind.nodes:
        if (value is! List) return error(path, 'expected a list of widgets');
        nodes(value, path);
      case PropKind.action:
        if (isAction(value)) refs.actions.add(value);
        if (!isAction(value)) {
          error(path, '"$value" is not an action; '
              'available: ${actions.isEmpty ? '(none)' : actions.join(', ')}');
        }
      case PropKind.binding:
        if (isBinding(value)) refs.values.add(value);
        if (!isBinding(value)) {
          error(path, '"$value" is not a value (app/views/values/); '
              'available: ${bindings.isEmpty ? '(none)' : bindings.join(', ')}');
        }
      case PropKind.module:
        if (modules.containsKey(value)) refs.modules.add(value);
        if (!modules.containsKey(value)) {
          error(path, '"$value" is not a module (a folder in modules/); '
              'available: ${modules.isEmpty ? '(none)' : modules.keys.join(', ')}');
        }
      case PropKind.inline:
        widget(widgetCatalog[inline]!, value, path);
      case PropKind.nodeMap:
        if (value is! Map) return error(path, 'expected a map of value: node');
        for (final entry in value.entries) {
          node(entry.value, '$path.${entry.key}');
        }
      case PropKind.icon:
        // A value returning an icon name (`icon: tripIcon`), like a color.
        if (isBinding(value)) {
          refs.values.add(value);
        } else if (!iconNames.contains(value)) {
          error(path, 'unknown icon "$value"; use a name from Icons in '
              'REFERENCE.md, or a value that returns one');
        }
      case PropKind.color:
        // A value returning a color name or hex (`color: chipFill`).
        if (isBinding(value)) {
          refs.values.add(value);
        } else if (!isColor(value)) {
          error(path, 'unknown color "$value"; use #RRGGBB, a name from '
              'Colors in REFERENCE.md, or a value that returns one');
        }
      case PropKind.number:
        if (isBinding(value)) {
          refs.values.add(value);
        } else if (value is! num) {
          error(path, 'expected a number or a value returning one, got "$value"');
        }
      case PropKind.bindingOrLiteral:
      case PropKind.literal:
        _literalParams(value);
        _recordNames(value);
    }
  }

  /// Records the values and labels a literal names: a bare string, or the
  /// strings and `value:`/`text:` entries of a list (text `spans`, dropdown
  /// `options`). Other map keys (`style:` and so on) are skipped: they hold
  /// variants, not names.
  void _recordNames(dynamic value) {
    if (value is String) {
      if (isBinding(value)) refs.values.add(value);
      if (isLabel(value)) refs.labels.add(value);
    } else if (value is List) {
      value.forEach(_recordNames);
    } else if (value is Map) {
      _recordNames(value['value']);
      _recordNames(value['text']);
      // A color from a value (`style: {color: chipInk}`).
      for (final e in value.entries) {
        if (_isColorKey(e.key) && isBinding(e.value)) {
          refs.values.add(e.value);
        }
      }
    }
  }

  /// A string shown as text: a value, a label, or literal text (which
  /// belongs in app/views/labels/).
  void text(String value, String path) {
    if (paramName(value) != null) return;
    if (isBinding(value)) refs.values.add(value);
    if (isLabel(value)) refs.labels.add(value);
    if (isBinding(value) || isLabel(value)) return;
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

/// Keys of a literal map that hold a color (`color`, `borderColor`): they
/// may name a value, resolved by the engine.
bool _isColorKey(Object? key) =>
    key is String && (key == 'color' || key.endsWith('Color'));
