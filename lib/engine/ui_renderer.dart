import 'dart:typed_data';
import 'dart:ui' show lerpDouble;

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
///
/// It also runs the scope's animated values (`@Animated`): see [_Motion].
class _Scope extends StatefulWidget {
  final UiRenderer renderer;
  final dynamic node;
  final Map<String, dynamic> params;

  const _Scope(this.renderer, this.node, this.params);

  @override
  State<_Scope> createState() => _ScopeState();
}

class _ScopeState extends State<_Scope>
    with TickerProviderStateMixin
    implements _Motion {
  /// Animated values this scope read, by their cache key.
  final _tracks = <String, _Track>{};
  bool _building = false;

  /// What it built last: shown as is while it fades out (see [Leaving]).
  Widget? _last;

  @override
  Widget build(BuildContext context) {
    // Inside a `fade:` case that is leaving: frozen as it was, so it never
    // shows the state that made it leave.
    final last = _last;
    if (last != null && Leaving.of(context)) return last;
    final renderer = widget.renderer;
    final reads = _Reads();
    // Depends on the locale: a new one rebuilds every scope.
    final language = renderer.language(Localizations.maybeLocaleOf(context));
    _building = true;
    final Widget child;
    try {
      child = _EngineUi(renderer, context, widget.params, reads, language, this)
          .node(widget.node);
    } finally {
      _building = false;
    }
    reads.open = false;
    if (reads.reads.isNotEmpty) {
      final selected = reads.reads.values.toList();
      context.select<StateBloc, List<dynamic>>((bloc) => [
            for (final (name, params) in selected)
              renderer.value(name, bloc.state, params),
          ]);
    }
    return _last = child;
  }

  @override
  dynamic animate(String key, dynamic target, Map<String, dynamic> spec) {
    final track = _tracks[key];
    // First read: shown as is (no animation on the first frame).
    if (track == null) {
      _tracks[key] = _Track(target);
      return target;
    }
    if (target != track.to) {
      final from = track.current(context);
      track.from = from;
      track.to = target;
      track.curve = parseCurve(spec['curve']);
      // A number going down may have its own duration (`reverseMs`).
      final down = from is num && target is num && target < from;
      final ms = (down ? spec['reverseMs'] : null) ?? spec['ms'] ?? 220;
      final controller = track.controller ??=
          AnimationController(vsync: this)..addListener(_tick);
      // Reduced motion (the device's setting), or no duration: at once.
      if (ms == 0 || MediaQuery.maybeDisableAnimationsOf(context) == true) {
        controller.value = 1;
      } else {
        controller
          ..duration = Duration(milliseconds: ms as int)
          ..forward(from: 0);
      }
    }
    return track.current(context);
  }

  // Each tick rebuilds this scope only; the state (the bloc) is untouched.
  void _tick() {
    if (mounted && !_building) setState(() {});
  }

  @override
  void dispose() {
    for (final t in _tracks.values) {
      t.controller?.dispose();
    }
    super.dispose();
  }
}

/// Where an animated value's in-between results come from: the scope
/// reading it, on a Flutter ticker. [animate] returns what to show for
/// [target] now, and starts easing toward it when it changes.
abstract interface class _Motion {
  dynamic animate(String key, dynamic target, Map<String, dynamic> spec);
}

/// One animated value in a scope: easing from [from] to [to].
class _Track {
  dynamic from;
  dynamic to;
  Curve curve = Curves.easeOut;
  AnimationController? controller;

  _Track(this.to) : from = to;

  /// What to show now: [to] when idle; colors (names or hex) and numbers in
  /// between; anything else switches at once.
  dynamic current(BuildContext context) {
    final c = controller;
    if (c == null || !c.isAnimating) return to;
    final t = curve.transform(c.value);
    if (from is num && to is num) {
      return lerpDouble(from as num, to as num, t);
    }
    final a = parseColor(from, context);
    final b = parseColor(to, context);
    if (a != null && b != null) {
      final color = Color.lerp(a, b, t)!;
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
    }
    return to;
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

  /// Runs this scope's animated values.
  final _Motion _motion;

  _EngineUi(this.renderer, this.context, this.params, this._reads,
      this.language, this._motion);

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
    final result = renderer.value(name, renderer.bloc.state, params);
    final spec = _program.animated[name];
    if (spec == null) return result;
    return _motion.animate(
        params.isEmpty ? name : '$name ${UiRenderer._paramsKey(params)}',
        result,
        spec);
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
      // A component called with arguments: its `.name`s replaced by them
      // (already resolved here: this node's own were replaced when its
      // scope was made).
      final component = renderer.widgets[type];
      if (component != null) {
        final args = node[type];
        if (args is! Map) return _Scope(renderer, component, params);
        // `index: 0` reaches its values and actions, as a list item's does.
        return _Scope(
            renderer,
            substituteParams(component, args),
            args['index'] is int ? {...params, 'index': args['index']} : params);
      }
      final spec = widgetCatalog[type];
      if (spec == null) return _error('Unknown widget "$type"');
      final props = normalizeProps(spec, node[type]);
      if (props == null) return _error('Invalid "$type" properties');
      return widget(type, _colors(spec, props));
    }
    return Text(node.toString());
  }

  /// [props] with the colors and numbers that name a value replaced by its
  /// result: color and number props, and color keys of literal maps
  /// (`style: {color: chipInk}`).
  Map<String, dynamic> _colors(WidgetSpec spec, Map<String, dynamic> props) {
    Map<String, dynamic>? out;
    for (final MapEntry(:key, :value) in props.entries) {
      final kind = spec.props[key];
      final resolved = kind == PropKind.color || kind == PropKind.number
          ? _colorValue(value)
          : value is Map && kind == PropKind.literal
              ? _colorsIn(value)
              : value;
      if (!identical(resolved, value)) (out ??= {...props})[key] = resolved;
    }
    return out ?? props;
  }

  dynamic _colorValue(dynamic value) =>
      value is String && _program.bindings.contains(value)
          ? _value(value)
          : value;

  Map _colorsIn(Map map) {
    Map? out;
    for (final MapEntry(:key, :value) in map.entries) {
      if (key is String && (key == 'color' || key.endsWith('Color'))) {
        final resolved = _colorValue(value);
        if (!identical(resolved, value)) (out ??= {...map})[key] = resolved;
      }
    }
    return out ?? map;
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
      _EngineUi(renderer, context, {...params, ...extra}, _reads, language,
          _motion);

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
