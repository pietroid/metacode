import 'dart:convert';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Evaluates binding functions from the `bindings/` package at runtime.
///
/// Bindings are expected to return JSON-encoded strings; the runtime decodes
/// them before handing values back to the UI.
class BindingRuntime {
  final String source;

  BindingRuntime({required this.source});

  dynamic call(
    String name,
    Map<String, dynamic> state, {
    Map<String, dynamic>? context,
  }) {
    final stateJson = jsonEncode(state);
    final ctxJson = jsonEncode(context ?? {});

    // dart_eval requires every positional argument to be provided, even
    // optional ones with default values.
    final args = [$String(stateJson), $String(ctxJson)];

    final result = eval(source, function: name, args: args);
    return jsonDecode(result as String);
  }
}
