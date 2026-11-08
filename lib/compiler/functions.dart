// Reads actions (app/actions/) and values (app/views/values/): checks their
// signatures with the analyzer (syntax only, no type resolution) and records
// what each one touches (state fields, labels, routes) for the index.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:app_ui/spec.dart';
import 'package:metacode/files/project_files.dart';

import 'issues.dart';
import 'models.dart';

class Param {
  final String name;
  final String type;
  const Param(this.name, this.type);
}

/// A public top-level function from app/actions/ or app/views/values/.
class UserFunction {
  final String name;
  final String file; // relative to its app folder
  final String returnType;
  final List<Param> params; // context params, after the State param

  /// The file's header comment, without the leading `name:` (see
  /// [headerComment]). Shown in the index.
  String doc = '';

  /// What the file's code (the function and its private helpers, not the
  /// tests) touches, found syntactically: `state.x` reads, `StateDelta(x:)`
  /// writes, `labels.x`, `Routes.x`, and whether it calls `core.api`.
  final Set<String> reads = {};
  final Set<String> writes = {};
  final Set<String> labels = {};
  final Set<String> routes = {};
  bool usesApi = false;

  UserFunction(this.name, this.file, this.returnType, this.params);
}

/// The leading comment block of a file (`//` or `#` lines), as one line of
/// text, without a leading `name:` and up to the first empty comment line.
/// Every app file starts with one: `// joinWaitlist: Validates the email...`.
String headerComment(String source, String name) {
  final lines = <String>[];
  for (final line in source.split('\n')) {
    final m = RegExp(r'^\s*(//+|#)\s?(.*)$').firstMatch(line);
    if (m == null) break;
    final text = m.group(2)!.trim();
    if (text.isEmpty) {
      if (lines.isEmpty) continue;
      break;
    }
    lines.add(text);
  }
  final doc = lines.join(' ');
  final prefix = '$name:';
  return doc.startsWith(prefix) ? doc.substring(prefix.length).trim() : doc;
}

/// Collects [UserFunction.reads], `writes`, `labels`, `routes`, `usesApi`.
class _Touches extends RecursiveAstVisitor<void> {
  final UserFunction fn;
  _Touches(this.fn);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _record(node.prefix.name, node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      _record(target.name, node.propertyName.name);
    }
    super.visitPropertyAccess(node);
  }

  void _record(String target, String member) {
    switch (target) {
      case 'state':
        fn.reads.add(member);
      case 'labels':
        fn.labels.add(member);
      case 'Routes':
        fn.routes.add(member);
      case 'core' when member == 'api':
        fn.usesApi = true;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // `StateDelta(...)` parses as a call when types aren't resolved.
    if (node.target == null && node.methodName.name == 'StateDelta') {
      _writes(node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == 'StateDelta') {
      _writes(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  void _writes(ArgumentList args) {
    for (final a in args.arguments.whereType<NamedExpression>()) {
      fn.writes.add(a.name.label.name);
    }
  }
}

/// Allowed Dart types for each context param.
const contextParamTypes = {
  'index': {'int'},
  'value': {'String', 'bool', 'num', 'int', 'double'},
};

/// Params only actions take, with their Dart type: `emit` applies a
/// StateDelta to the state, `core` reaches the api and the navigator.
const actionParamTypes = {
  'emit': 'void Function(StateDelta)',
  'core': 'Core',
};

/// Params every function can take: `labels` reads app/views/labels/ (the
/// current language).
const sharedParamTypes = {'labels': 'Labels'};

const _actionKinds = {'actions'};

/// Reads every `.dart` file in `$appDir/$folder` of [files] (recursively;
/// [appDir] is `''` for the root app) and returns
/// its public functions.
///
/// Every function must take the `State` as its first parameter; further
/// parameters are matched by name: context params (see [contextParams]) and,
/// for actions, `emit` and `core` (see [actionParamTypes]). Actions return
/// `Future<void>` and change the state only through `emit`; values return
/// something the engine can hand to the UI.
List<UserFunction> readFunctions(
  ProjectFiles files,
  String appDir,
  String folder, // 'app/actions' or 'app/views/values'
  String kind, // 'actions' or 'values'
  Map<String, Model> models,
  Issues issues,
) {
  final functions = <UserFunction>[];
  final skip = appDir.isEmpty ? 0 : appDir.length + 1;
  for (final path in files.list(
      appDir.isEmpty ? folder : '$appDir/$folder',
      recursive: true)) {
    if (!isUserCode(path)) continue;
    if (path.split('/').last.startsWith('_')) continue;
    final rel = path.substring(skip);
    final source = files.read(path)!;
    final result = parseString(
      content: source,
      path: '/$path',
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
      if (name == testsFunction) continue;

      final fn = _readFunction(decl, name, rel, kind, models, issues);
      if (fn == null) continue;
      fn.doc = headerComment(source, name);
      final touches = _Touches(fn);
      for (final d in result.unit.declarations) {
        if (d is FunctionDeclaration && d.name.lexeme == testsFunction) continue;
        d.accept(touches);
      }
      functions.add(fn);
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

    final sharedType = sharedParamTypes[paramName];
    if (sharedType != null) {
      if (type != sharedType) {
        fail('"$paramName" must be $sharedType, got $type');
        return null;
      }
      params.add(Param(paramName, sharedType));
      continue;
    }

    final actionType = actionParamTypes[paramName];
    if (actionType != null) {
      if (!_actionKinds.contains(kind)) {
        fail('"$paramName" is only available to actions');
        return null;
      }
      // `void Function(StateDelta delta)` is fine too.
      final normalized = type.replaceAll(RegExp(r'\s+\w+\)$'), ')');
      if (normalized != actionType) {
        fail('"$paramName" must be $actionType, got $type');
        return null;
      }
      params.add(Param(paramName, actionType));
      continue;
    }

    final allowed = contextParamTypes[paramName];
    if (allowed == null) {
      final available = [
        ...contextParams,
        ...sharedParamTypes.keys,
        if (_actionKinds.contains(kind)) ...actionParamTypes.keys,
      ];
      fail('unknown parameter "$paramName"; available: ${available.join(', ')}');
      return null;
    }
    if (!allowed.contains(type)) {
      fail('"$paramName" must be ${allowed.join(' or ')}, got $type');
      return null;
    }
    params.add(Param(paramName, type));
  }

  final returnType = decl.returnType?.toSource() ?? 'dynamic';
  if (_actionKinds.contains(kind)) {
    if (returnType != 'Future<void>') {
      fail('actions return Future<void> and change the state with '
          'emit(StateDelta(...)), got "$returnType"');
      return null;
    }
  } else if (!isEncodable(returnType, models)) {
    fail('values must return a model, enum, primitive or List of those, '
        'got "$returnType"');
    return null;
  }

  return UserFunction(name, file, returnType, params);
}

/// Whether [path] is user code the engine runs.
bool isUserCode(String path) => path.endsWith('.dart');

/// Each action or value file holds its own tests in a top-level `main()`,
/// below the function. The tool ignores it and [stripTests] drops it before
/// compiling, so it never reaches the engine.
const testsFunction = 'main';

/// [source] without its top-level `main()` (the file's tests).
String stripTests(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  for (final decl in unit.declarations.reversed) {
    if (decl is FunctionDeclaration && decl.name.lexeme == testsFunction) {
      source = source.replaceRange(decl.offset, decl.end, '');
    }
  }
  return source;
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
