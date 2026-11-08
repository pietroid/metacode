import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'host_plugin.dart';

/// The project's actions and bindings, precompiled by `tool/metacode.dart`
/// into dart_eval bytecode and loaded once at startup.
///
/// The engine talks JSON to the generated bridge (`.generated/main.dart`),
/// which hands typed objects to the user's functions. Actions reach back
/// through [host]: `emit` deltas and `Core` calls (api, navigator).
class MetacodeProgram {
  late final Runtime _runtime;
  final Set<String> actions;
  final Set<String> bindings;

  /// Values marked `@Animated`: name -> `{ms, curve}`.
  final Map<String, Map<String, dynamic>> animated;

  /// Receives what actions emit and ask for. Set by the app (or a test)
  /// before running actions.
  MetacodeHost host = const _NoHost();

  static const _library = 'package:metacode/main.dart';

  MetacodeProgram(ByteData bytecode, Map<String, dynamic> manifest)
      : actions = Set<String>.from(manifest['actions'] as List),
        bindings = Set<String>.from(manifest['bindings'] as List),
        animated = {
          for (final e in ((manifest['animated'] as Map?) ?? const {}).entries)
            e.key as String: Map<String, dynamic>.from(e.value as Map),
        } {
    _runtime = Runtime(bytecode)..addPlugin(HostPlugin(() => host));
  }

  /// Runs an action. It changes the state only through `emit` (see [host]),
  /// possibly several times, and completes when the action returns.
  Future<void> action(
    String name,
    Map<String, dynamic> state, [
    Map<String, dynamic> params = const {},
  ]) async {
    var result = _execute('\$action_$name', state, params);
    if (result is $Value) result = result.$value;
    await (result as Future);
  }

  /// Evaluates a binding. [context] carries e.g. the list `index`.
  dynamic binding(
    String name,
    Map<String, dynamic> state, [
    Map<String, dynamic> context = const {},
  ]) {
    final result = _execute('\$binding_$name', state, context);
    return jsonDecode((result is $Value ? result.$reified : result) as String);
  }

  dynamic _execute(String function, Map<String, dynamic> state, Map params) =>
      _runtime.executeLib(_library, function, [
        $String(_encode(state)),
        $String(params.isEmpty ? '{}' : jsonEncode(params)),
      ]);

  // A build evaluates many values on the same state map (the engine
  // replaces the map on every change, never mutates it), so encode it once.
  Map<String, dynamic>? _encodedState;
  String _encodedJson = '';

  String _encode(Map<String, dynamic> state) {
    if (!identical(state, _encodedState)) {
      _encodedState = state;
      _encodedJson = jsonEncode(state);
    }
    return _encodedJson;
  }
}

class _NoHost implements MetacodeHost {
  const _NoHost();

  @override
  void emit(Map<String, dynamic> delta) =>
      throw StateError('MetacodeProgram.host is not set');

  @override
  Future<Object?> call(String op, Map<String, dynamic> args) =>
      throw StateError('MetacodeProgram.host is not set');
}
