import 'dart:convert';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// What the interpreted program can ask of the engine: apply state deltas
/// and run host operations (http, navigation). The app implements it in
/// `core_host.dart`; tests use a fake (`.generated/test_app.dart`).
abstract class MetacodeHost {
  /// Merges a top-level state delta (JSON, same encoding as the state).
  void emit(Map<String, dynamic> delta);

  /// Runs [op] (`api`, `navigator.push`, `navigator.pop`) and returns a
  /// JSON-encodable result. Should not throw: report failures in the result
  /// (an api failure is `{status: 0, body: error}`).
  Future<Object?> call(String op, Map<String, dynamic> args);
}

/// Bridges `package:metacode/engine/host.dart` (see host.dart) into dart_eval.
///
/// The tool adds it to the compiler (declarations only); the engine adds it
/// to the runtime with a [host] getter.
class HostPlugin implements EvalPlugin {
  static const library = 'package:metacode/engine/host.dart';

  final MetacodeHost Function()? host;

  const HostPlugin([this.host]);

  @override
  String get identifier => library;

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    BridgeTypeAnnotation type(BridgeTypeRef ref) => BridgeTypeAnnotation(ref);
    final string = type(BridgeTypeRef(CoreTypes.string));

    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      library,
      'hostCall',
      BridgeFunctionDef(
        returns: type(BridgeTypeRef(CoreTypes.future, [string])),
        params: [
          BridgeParameter('op', string, false),
          BridgeParameter('args', string, false),
        ],
      ),
    ));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      library,
      'hostEmit',
      BridgeFunctionDef(
        returns: type(BridgeTypeRef(CoreTypes.voidType)),
        params: [BridgeParameter('delta', string, false)],
      ),
    ));
  }

  @override
  void configureForRuntime(Runtime runtime) {
    final host = this.host;
    if (host == null) return;

    runtime.registerBridgeFunc(library, 'hostCall', (runtime, target, args) {
      final op = args[0]!.$value as String;
      final json = jsonDecode(args[1]!.$value as String) as Map;
      final result = host()
          .call(op, Map<String, dynamic>.from(json))
          .then<$Value>((r) => $String(jsonEncode(r)));
      return $Future.wrap(result);
    });

    runtime.registerBridgeFunc(library, 'hostEmit', (runtime, target, args) {
      final delta = jsonDecode(args[0]!.$value as String) as Map;
      host().emit(Map<String, dynamic>.from(delta));
      return null;
    });
  }
}
