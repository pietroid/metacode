import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import 'program.dart';
import 'state_bloc.dart';

/// Renders one app's ui/ widgets with the `app_ui` catalog.
///
/// Resolves node references (widget ids, relations, literals), expands
/// shorthands, and gives widget builders a [Ui] wired to the program.
/// Actions run against [bloc]; `app:` widgets are built by [embed].
class UiRenderer {
  final Map<String, dynamic> widgets;
  final MetacodeProgram program;
  final StateBloc bloc;
  final Widget Function(String app) embed;

  UiRenderer({
    required Map<String, dynamic> ui,
    required this.program,
    required this.bloc,
    required this.embed,
  }) : widgets = Map<String, dynamic>.from(ui['widgets'] ?? {});

  // Relations are pure functions of (state, params), so their values are
  // kept until the state changes: rebuilds that don't change the state
  // (resizing, a parent rebuilding, the same relation used twice) don't run
  // the interpreter again.
  Map<String, dynamic>? _cachedState;
  final _cache = <String, dynamic>{};

  dynamic relation(String name, Map<String, dynamic> state,
      Map<String, dynamic> params) {
    if (!identical(state, _cachedState)) {
      _cachedState = state;
      _cache.clear();
    }
    final key = params.isEmpty ? name : '$name ${_paramsKey(params)}';
    if (_cache.containsKey(key)) return _cache[key];
    return _cache[key] = program.binding(name, state, params);
  }

  static String _paramsKey(Map<String, dynamic> params) =>
      [for (final e in params.entries) '${e.key}=${e.value}'].join('&');

  Widget build(BuildContext context, String id, Map<String, dynamic> state) =>
      _EngineUi(this, context, state, const {}).node(id);
}

class _EngineUi implements Ui {
  final UiRenderer renderer;
  @override
  final BuildContext context;
  final Map<String, dynamic> state;
  final Map<String, dynamic> params;

  _EngineUi(this.renderer, this.context, this.state, this.params);

  MetacodeProgram get _program => renderer.program;

  @override
  Widget node(dynamic node) {
    if (node == null) return const SizedBox.shrink();
    if (node is String) {
      final widget = renderer.widgets[node];
      if (widget != null) return this.node(widget);
      return Text((resolve(node) ?? '').toString());
    }
    if (node is Map && node.length == 1) {
      final type = node.keys.first.toString();
      final spec = widgetCatalog[type];
      if (spec == null) return _error('Unknown widget "$type"');
      final props = normalizeProps(spec, node[type]);
      if (props == null) return _error('Invalid "$type" properties');
      return widget(type, props);
    }
    return Text(node.toString());
  }

  @override
  List<Widget> nodes(dynamic nodes) =>
      nodes is List ? [for (final n in nodes) node(n)] : [node(nodes)];

  @override
  Widget widget(String type, Map<String, dynamic> props) {
    final builder = widgetBuilders[type];
    if (builder == null) return _error('No builder for "$type"');
    return builder(this, props);
  }

  @override
  dynamic binding(dynamic name) => name is String && _program.bindings.contains(name)
      ? renderer.relation(name, state, params)
      : null;

  @override
  dynamic resolve(dynamic value) =>
      value is String && _program.bindings.contains(value)
          ? renderer.relation(value, state, params)
          : value;

  @override
  Widget app(String name) => renderer.embed(name);

  @override
  VoidCallback? action(dynamic name) =>
      _isAction(name) ? () => _run(name as String, const {}) : null;

  @override
  ValueChanged<T>? actionWithValue<T>(dynamic name) =>
      _isAction(name) ? (T v) => _run(name as String, {'value': v}) : null;

  @override
  Ui withParams(Map<String, dynamic> extra) =>
      _EngineUi(renderer, context, state, {...params, ...extra});

  bool _isAction(dynamic name) =>
      name is String && _program.actions.contains(name);

  /// Runs an action on the latest state. It changes the state through
  /// `emit` (see CoreHost), so nothing is applied here.
  Future<void> _run(String name, Map<String, dynamic> extra) async {
    final bloc = renderer.bloc;
    try {
      await _program.action(name, bloc.state, {...params, ...extra});
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'metacode',
        context: ErrorDescription('while running action "$name"'),
      ));
    }
  }

  Widget _error(String message) =>
      Text(message, style: const TextStyle(color: Colors.red));
}
