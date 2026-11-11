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

  /// Remote actions (the backend's program, app/actions/remote/).
  final Set<String> remoteActions;

  /// The state fields each value reads (manifest `reads`, through shared
  /// helpers too); a value missing here may read any field.
  final Map<String, List<String>> reads;

  /// Values marked `@Animated`: name -> `{ms, curve}`.
  final Map<String, Map<String, dynamic>> animated;

  /// Receives what actions emit and ask for. Set by the app (or a test)
  /// before running actions.
  MetacodeHost host = const _NoHost();

  static const _library = 'package:metacode/main.dart';

  MetacodeProgram(ByteData bytecode, Map<String, dynamic> manifest)
      : actions = Set<String>.from((manifest['actions'] as List?) ?? const []),
        bindings = Set<String>.from((manifest['bindings'] as List?) ?? const []),
        remoteActions = Set<String>.from((manifest['remote'] as List?) ?? const []),
        reads = {
          for (final e in ((manifest['reads'] as Map?) ?? const {}).entries)
            e.key as String: List<String>.from(e.value as List),
        },
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

  /// Runs a remote action (`$remote_<name>` in the backend's program):
  /// returns '' when it finished, else the code of the `RemoteError` it
  /// threw, or `failed` when it crashed. Its deltas go to [host]'s `emit`
  /// (the caller drops them unless it returned '').
  Future<String> remote(
    String name,
    Map<String, dynamic> state, [
    Map<String, dynamic> params = const {},
  ]) async {
    if (!remoteActions.contains(name)) return 'unknownAction';
    try {
      var result = _execute('\$remote_$name', state, params);
      if (result is $Value) result = result.$value;
      final out = await (result as Future);
      return (out is $Value ? out.$value : out) as String;
    } catch (e) {
      final code = _remoteErrorCode(e);
      if (code != null) return code;
      // ignore: avoid_print
      print('metacode: remote action "$name" failed: $e');
      return 'failed';
    }
  }

  /// The code of a thrown interpreted `RemoteError`, else null.
  String? _remoteErrorCode(Object error) {
    if (error is! $Instance) return null;
    try {
      final code = error.$getProperty(_runtime, 'code');
      final value = code is $Value ? code.$value : code;
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// How many times each value ran in the interpreter (for tests: the
  /// renderer reruns a value only when a field it reads changed).
  final Map<String, int> runs = {};

  /// Evaluates a binding. [context] carries e.g. the list `index`.
  dynamic binding(
    String name,
    Map<String, dynamic> state, [
    Map<String, dynamic> context = const {},
  ]) {
    runs[name] = (runs[name] ?? 0) + 1;
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
