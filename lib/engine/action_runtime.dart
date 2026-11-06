import 'dart:convert';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Evaluates action functions from the `actions/` package at runtime.
///
/// Actions receive the current state and optional params as JSON strings and
/// return a JSON-encoded new state.
class ActionRuntime {
  final String source;

  ActionRuntime({required this.source});

  Map<String, dynamic> call(
    String name,
    Map<String, dynamic> state, {
    Map<String, dynamic>? params,
  }) {
    final stateJson = jsonEncode(state);
    final paramsJson = jsonEncode(params ?? {});

    // dart_eval requires every positional argument to be provided, even
    // optional ones with default values.
    final args = [$String(stateJson), $String(paramsJson)];

    final result = eval(source, function: name, args: args);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }
}
