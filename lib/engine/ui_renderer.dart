import 'dart:typed_data';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale.dart';
import 'program.dart';
import 'state_bloc.dart';

/// Renders one app's app/views/ widgets with the `app_ui` catalog.
///
/// Resolves node references (pages and components, values, labels,
/// literals), expands
/// shorthands, and gives widget builders a [Ui] wired to the program.
/// Actions run against [bloc]; `module:` widgets are built by [embed].
class UiRenderer {
  final Map<String, dynamic> widgets;
  final MetacodeProgram program;

  /// app/views/labels/: language -> key -> text (see [ProjectConfig.labels]).
  final Map<String, Map<String, String>> labels;
  final String? defaultLanguage;
  final StateBloc bloc;
  final Widget Function(String app, {bool contained}) embed;

  /// Called with the tapped widget's context before an action runs, so
  /// `core.navigator` uses the navigator the tap came from.
  final void Function(BuildContext context)? onAction;

  /// App files by repo-relative path, when running from the project's
  /// files (see [ProjectConfig.readFile]).
  final Uint8List? Function(String path)? readFile;

  UiRenderer({
    required Map<String, dynamic> ui,
    required this.program,
    this.labels = const {},
    this.defaultLanguage,
    required this.bloc,
    required this.embed,
    this.onAction,
    this.readFile,
  }) : widgets = Map<String, dynamic>.from(ui['widgets'] ?? {});

  // Values are pure functions of (state, params), so their values are
  // kept until the state changes: rebuilds that don't change the state
  // (resizing, a parent rebuilding, the same value used twice) don't run
  // the interpreter again.
  Map<String, dynamic>? _cachedState;
  final _cache = <String, dynamic>{};

  dynamic value(String name, Map<String, dynamic> state,
      Map<String, dynamic> params) {
    if (!identical(state, _cachedState)) {
      _cachedState = state;
      _cache.clear();
    }
    final key = params.isEmpty ? name : '$name ${_paramsKey(params)}';
    if (_cache.containsKey(key)) return _cache[key];
    return _cache[key] = program.binding(name, state, params);
  }

  /// This app's language for the locale Flutter resolved (see
  /// engine/locale.dart): the labels file that fits it, else the default.
  String? language(Locale? locale) =>
      (locale == null ? null : matchLanguage(labels.keys, locale)) ??
      defaultLanguage;

  final _labelsIn = <String?, Map<String, String>>{};

  /// The labels of [language], over the default language's.
  Map<String, String> labelsIn(String? language) =>
      _labelsIn[language] ??= {
        ...?labels[defaultLanguage],
        ...?labels[language],
      };

  static String _paramsKey(Map<String, dynamic> params) =>
      [for (final e in params.entries) '${e.key}=${e.value}'].join('&');

  /// The page or component [id], under a `BlocProvider` of [bloc]
  /// (each app's widgets select from their own app's state).
  Widget build(String id) => BlocProvider<StateBloc>.value(
        value: bloc,
        child: _Scope(this, widgets[id] ?? id, const {}),
      );
}

/// The values one scope read while building, with their params.
class _Reads {
  /// Whether the scope is building: reads are recorded and child nodes
  /// are built inline. After that (a `ListView` item, a `LayoutBuilder`),
  /// child nodes become scopes of their own.
  bool open = true;
  final reads = <String, (String, Map<String, dynamic>)>{};
}

/// One page or component (or a lazily built node such as a list item).
///
/// Builds its node, recording the values it reads, then `context.select`s
/// exactly those values: it rebuilds only when one of their results
/// changes, not on every state change. Nested pages and components are
/// scopes of their own, so they are not part of this one's selection.
class _Scope extends StatelessWidget {
  final UiRenderer renderer;
  final dynamic node;
  final Map<String, dynamic> params;

  const _Scope(this.renderer, this.node, this.params);

  @override
  Widget build(BuildContext context) {
    final reads = _Reads();
    // Depends on the locale: a new one rebuilds every scope.
    final language = renderer.language(Localizations.maybeLocaleOf(context));
    final child =
        _EngineUi(renderer, context, params, reads, language).node(node);
    reads.open = false;
    if (reads.reads.isNotEmpty) {
      final selected = reads.reads.values.toList();
      context.select<StateBloc, List<dynamic>>((bloc) => [
            for (final (name, params) in selected)
              renderer.value(name, bloc.state, params),
          ]);
    }
    return child;
  }
}

class _EngineUi implements Ui {
  final UiRenderer renderer;
  @override
  final BuildContext context;
  final Map<String, dynamic> params;
  final _Reads _reads;

  /// The labels file shown (`pt_br`), passed to user code as `_locale`.
  final String? language;

  _EngineUi(this.renderer, this.context, this.params, this._reads, this.language);

  MetacodeProgram get _program => renderer.program;

  /// [params] for user code, with the language its `labels` are in.
  Map<String, dynamic> get _callParams =>
      language == null ? params : {...params, '_locale': language};

  /// A value on the latest state, recorded for the scope's selection.
  dynamic _value(String name) {
    final params = _callParams;
    if (_reads.open) {
      _reads.reads.putIfAbsent(
          params.isEmpty ? name : '$name ${UiRenderer._paramsKey(params)}',
          () => (name, params));
    }
    return renderer.value(name, renderer.bloc.state, params);
  }

  @override
  Widget node(dynamic node) {
    if (node == null) return const SizedBox.shrink();
    // Built after the scope (list items, layout builders): its own scope.
    if (!_reads.open) return _Scope(renderer, node, params);
    if (node is String) {
      final widget = renderer.widgets[node];
      // Pages and components select their own values.
      if (widget != null) return _Scope(renderer, widget, params);
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
    return buildCatalogWidget(this, type, props) ??
        _error('No builder for "$type"');
  }

  @override
  dynamic binding(dynamic name) => name is String && _program.bindings.contains(name)
      ? _value(name)
      : null;

  @override
  dynamic resolve(dynamic value) {
    if (value is! String) return value;
    if (_program.bindings.contains(value)) {
      return _value(value);
    }
    return renderer.labelsIn(language)[value] ?? value;
  }

  @override
  Widget module(String name, {bool contained = false}) =>
      renderer.embed(name, contained: contained);

  @override
  VoidCallback? action(dynamic name) =>
      _isAction(name) ? () => _run(name as String, const {}) : null;

  @override
  ValueChanged<T>? actionWithValue<T>(dynamic name) =>
      _isAction(name) ? (T v) => _run(name as String, {'value': v}) : null;

  @override
  Uint8List? file(String path) => renderer.readFile?.call(path);

  @override
  Ui withParams(Map<String, dynamic> extra) =>
      _EngineUi(renderer, context, {...params, ...extra}, _reads, language);

  bool _isAction(dynamic name) =>
      name is String && _program.actions.contains(name);

  /// Runs an action on the latest state. It changes the state through
  /// `emit` (see CoreHost), so nothing is applied here.
  Future<void> _run(String name, Map<String, dynamic> extra) async {
    final bloc = renderer.bloc;
    if (context.mounted) renderer.onAction?.call(context);
    try {
      await _program.action(name, bloc.state, {..._callParams, ...extra});
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
