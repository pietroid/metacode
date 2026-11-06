import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// The project's actions and bindings, precompiled by `tool/metacode.dart`
/// into dart_eval bytecode and loaded once at startup.
///
/// The engine talks JSON to the generated bridge (`generated/main.dart`),
/// which hands typed objects to the user's functions.
class MetacodeProgram {
  final Runtime _runtime;
  final Set<String> actions;
  final Set<String> bindings;

  static const _library = 'package:metacode/main.dart';

  MetacodeProgram(ByteData bytecode, Map<String, dynamic> manifest)
      : _runtime = Runtime(bytecode),
        actions = Set<String>.from(manifest['actions'] as List),
        bindings = Set<String>.from(manifest['bindings'] as List);

  /// Runs an action and returns the next state.
  Map<String, dynamic> action(
    String name,
    Map<String, dynamic> state, [
    Map<String, dynamic> params = const {},
  ]) {
    return Map<String, dynamic>.from(
      jsonDecode(_call('\$action_$name', state, params)) as Map,
    );
  }

  /// Evaluates a binding. [context] carries e.g. the list `index`.
  dynamic binding(
    String name,
    Map<String, dynamic> state, [
    Map<String, dynamic> context = const {},
  ]) {
    return jsonDecode(_call('\$binding_$name', state, context));
  }

  String _call(String function, Map<String, dynamic> state, Map params) {
    final result = _runtime.executeLib(_library, function, [
      $String(jsonEncode(state)),
      $String(jsonEncode(params)),
    ]);
    return (result is $Value ? result.$reified : result) as String;
  }
}
