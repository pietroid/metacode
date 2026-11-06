import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:app_ui/spec.dart';

import 'issues.dart';
import 'models.dart';

class Param {
  final String name;
  final String type;
  const Param(this.name, this.type);
}

/// A public top-level function from actions/ or bindings/.
class UserFunction {
  final String name;
  final String file; // relative to the metacode/ folder
  final String returnType;
  final List<Param> params; // context params, after the State param

  const UserFunction(this.name, this.file, this.returnType, this.params);
}

/// Allowed Dart types for each context param.
const _contextParamTypes = {
  'index': {'int'},
  'value': {'String', 'bool', 'num', 'int', 'double'},
};

/// Reads every `.dart` file in [dir] and returns its public functions.
///
/// Every function must take the `State` as its first parameter; further
/// parameters are context params (see [contextParams]). Actions must return
/// `State`; bindings must return something the engine can hand to the UI.
List<UserFunction> readFunctions(
  Directory dir,
  String kind, // 'actions' or 'bindings'
  Map<String, Model> models,
  Issues issues,
) {
  final functions = <UserFunction>[];
  if (!dir.existsSync()) return functions;

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final rel = '$kind/${file.uri.pathSegments.last}';
    final result = parseString(
      content: file.readAsStringSync(),
      path: file.path,
      throwIfDiagnostics: false,
    );
    for (final d in result.errors) {
      final line = result.lineInfo.getLocation(d.offset).lineNumber;
      issues.error(rel, 'line $line', d.message);
    }

    for (final decl in result.unit.declarations) {
      if (decl is! FunctionDeclaration) continue;
      final name = decl.name.lexeme;
      if (name.startsWith('_') || decl.isGetter || decl.isSetter) continue;

      final fn = _readFunction(decl, name, rel, kind, models, issues);
      if (fn != null) functions.add(fn);
    }
  }
  return functions;
}

UserFunction? _readFunction(
  FunctionDeclaration decl,
  String name,
  String file,
  String kind,
  Map<String, Model> models,
  Issues issues,
) {
  void fail(String message) => issues.error(file, name, message);

  final parameters = decl.functionExpression.parameters?.parameters ?? [];
  if (parameters.isEmpty) {
    fail('must take the state as its first parameter: $name(State state)');
    return null;
  }

  final params = <Param>[];
  for (var i = 0; i < parameters.length; i++) {
    final p = parameters[i];
    if (p is! SimpleFormalParameter || !p.isRequiredPositional) {
      fail('use plain positional parameters only');
      return null;
    }
    final type = p.type?.toSource() ?? 'dynamic';
    final paramName = p.name?.lexeme ?? '';

    if (i == 0) {
      if (type != 'State') {
        fail('first parameter must be the State, got "$type $paramName"');
        return null;
      }
      continue;
    }

    final allowed = _contextParamTypes[paramName];
    if (allowed == null) {
      fail('unknown parameter "$paramName"; available: '
          '${contextParams.join(', ')}');
      return null;
    }
    if (!allowed.contains(type)) {
      fail('"$paramName" must be ${allowed.join(' or ')}, got $type');
      return null;
    }
    params.add(Param(paramName, type));
  }

  final returnType = decl.returnType?.toSource() ?? 'dynamic';
  if (kind == 'actions') {
    if (returnType != 'State') {
      fail('actions must return the next State, got "$returnType"');
      return null;
    }
  } else if (!isEncodable(returnType, models)) {
    fail('bindings must return a model, enum, primitive or List of those, '
        'got "$returnType"');
    return null;
  }

  return UserFunction(name, file, returnType, params);
}

const _primitiveDartTypes = {'String', 'bool', 'int', 'double', 'num', 'DateTime'};

/// Whether the engine can encode a value of this Dart type for the UI.
bool isEncodable(String type, Map<String, Model> models) {
  var t = type.trim();
  if (t.endsWith('?')) t = t.substring(0, t.length - 1);
  if (_primitiveDartTypes.contains(t)) return true;
  final list = RegExp(r'^List<(.+)>$').firstMatch(t);
  if (list != null) return isEncodable(list.group(1)!, models);
  return models.values.any((m) => m.className == t);
}
