import 'issues.dart';

/// Primitive model types and the Dart types they map to.
const primitives = {
  'string': 'String',
  'boolean': 'bool',
  'number': 'num',
  'datetime': 'DateTime',
};

/// A field type such as `string`, `task?` or `list(task)`.
class TypeRef {
  final String name; // a primitive, a model name, or 'list'
  final TypeRef? item; // set when name == 'list'
  final bool optional;

  const TypeRef(this.name, {this.item, this.optional = false});

  bool get isList => name == 'list';

  static final _list = RegExp(r'^list\((.+)\)(\?)?$');
  static final _named = RegExp(r'^([a-zA-Z][a-zA-Z0-9]*)(\?)?$');

  static TypeRef? parse(String source) {
    final s = source.trim();
    final list = _list.firstMatch(s);
    if (list != null) {
      final item = parse(list.group(1)!);
      if (item == null) return null;
      return TypeRef('list', item: item, optional: list.group(2) != null);
    }
    final named = _named.firstMatch(s);
    if (named != null) {
      return TypeRef(named.group(1)!, optional: named.group(2) != null);
    }
    return null;
  }

  @override
  String toString() =>
      '${isList ? 'list($item)' : name}${optional ? '?' : ''}';
}

sealed class Model {
  final String name;
  const Model(this.name);

  String get className => name[0].toUpperCase() + name.substring(1);
}

class ClassModel extends Model {
  final Map<String, TypeRef> fields;
  const ClassModel(super.name, this.fields);
}

class EnumModel extends Model {
  final List<String> values;
  const EnumModel(super.name, this.values);
}

/// The reserved model that types state.yaml.
const stateModelName = 'state';

/// Validates the models (every file in [file], merged).
///
/// If [baseModels] is provided, models can reference those types and new
/// class names must not clash with them. The reserved `state` model is
/// parsed from `archetypes/state.yaml`; this function does not require it.
Map<String, Model> parseModels(dynamic doc, Issues issues,
    {String file = 'models/', Map<String, Model>? baseModels}) {
  final models = <String, Model>{...?baseModels};

  if (doc is! Map) {
    issues.error(file, '', 'must be a map of model names to definitions');
    return models;
  }

  for (final entry in doc.entries) {
    final name = entry.key.toString();
    final value = entry.value;

    if (!isValidName(name)) {
      issues.error(file, name, 'invalid model name');
      continue;
    }
    if (primitives.containsKey(name) || name == 'list') {
      issues.error(file, name, '"$name" is a primitive type name');
      continue;
    }

    if (value is List) {
      final values = <String>[];
      for (final v in value) {
        final s = v.toString();
        if (!isValidName(s)) {
          issues.error(file, name, 'invalid enum value "$s"');
        } else if (values.contains(s)) {
          issues.error(file, name, 'duplicate enum value "$s"');
        } else {
          values.add(s);
        }
      }
      if (values.isEmpty) issues.error(file, name, 'enum has no values');
      models[name] = EnumModel(name, values);
    } else if (value is Map) {
      final fields = <String, TypeRef>{};
      for (final field in value.entries) {
        final fieldName = field.key.toString();
        if (!isValidName(fieldName)) {
          issues.error(file, '$name.$fieldName', 'invalid field name');
          continue;
        }
        final type = TypeRef.parse(field.value?.toString() ?? '');
        if (type == null) {
          issues.error(file, '$name.$fieldName',
              'invalid type "${field.value}" (use e.g. string, task?, list(task))');
          continue;
        }
        fields[fieldName] = type;
      }
      models[name] = ClassModel(name, fields);
    } else {
      issues.error(file, name,
          'must be a map of fields (a model) or a list of values (an enum)');
    }
  }

  final classNames = <String, String>{};
  for (final model in models.values) {
    final other = classNames[model.className];
    if (other != null) {
      issues.error(file, model.name,
          'clashes with "$other" (both become ${model.className})');
    }
    classNames[model.className] = model.name;

    if (model is ClassModel) {
      for (final field in model.fields.entries) {
        _checkResolves(
            field.value, models, issues, '${model.name}.${field.key}', file);
      }
    }
  }

  return models;
}

void _checkResolves(TypeRef type, Map<String, Model> models, Issues issues,
    String path, String file) {
  if (type.isList) {
    _checkResolves(type.item!, models, issues, path, file);
  } else if (!primitives.containsKey(type.name) &&
      !models.containsKey(type.name)) {
    issues.error(file, path, 'unknown type "${type.name}"');
  }
}

/// Validates the `state` map (app.yaml's `state:`, or a test state in
/// tests/ over it: [file]) against the reserved `state` model.
void validateState(dynamic doc, Map<String, Model> models, Issues issues,
    {String file = 'app.yaml'}) {
  final stateModel = models[stateModelName];
  if (stateModel is! ClassModel) return;

  if (doc is! Map || doc['state'] is! Map) {
    issues.error(file, '', 'must contain a top-level "state:" map');
    return;
  }
  _validateValue(doc['state'], const TypeRef(stateModelName), models, issues,
      'state', file);
}

/// A YAML key that can't be a field name, with no value: the tail of an
/// unquoted flow-map value cut at a comma (`{blurb: Fewer carbs, steady
/// energy}` reads `steady energy` as a key).
final _splitFlowKey = RegExp(r'[^A-Za-z0-9_]');

void _validateValue(dynamic value, TypeRef type, Map<String, Model> models,
    Issues issues, String path, String file) {
  void fail(String message) => issues.error(file, path, message);

  if (value == null) {
    if (!type.optional) fail('is required ($type)');
    return;
  }

  if (type.isList) {
    if (value is! List) return fail('expected a list ($type)');
    for (var i = 0; i < value.length; i++) {
      _validateValue(value[i], type.item!, models, issues, '$path[$i]', file);
    }
    return;
  }

  switch (type.name) {
    case 'string':
      if (value is! String) fail('expected a string, got "$value"');
    case 'boolean':
      if (value is! bool) fail('expected true or false, got "$value"');
    case 'number':
      if (value is! num) fail('expected a number, got "$value"');
    case 'datetime':
      if (value is! String || DateTime.tryParse(value) == null) {
        fail('expected a date like "2026-11-05" or "2026-11-05T10:30:00", got "$value"');
      }
    default:
      final model = models[type.name];
      if (model is EnumModel) {
        if (!model.values.contains(value.toString())) {
          fail('expected one of ${model.values.join(', ')}, got "$value"');
        }
      } else if (model is ClassModel) {
        if (value is! Map) return fail('expected a ${model.name} (map)');
        for (final key in value.keys) {
          if (model.fields.containsKey(key.toString())) continue;
          if (value[key] == null && _splitFlowKey.hasMatch(key.toString())) {
            issues.error(file, path,
                '"$key" is not a field of ${model.name}: an unquoted comma in '
                'a {key: value} map ends the value there; quote the text '
                '(name: "Fish, rice")');
          } else {
            issues.error(file, '$path.$key', 'not a field of ${model.name}');
          }
        }
        for (final field in model.fields.entries) {
          _validateValue(value[field.key], field.value, models, issues,
              '$path.${field.key}', file);
        }
      }
  }
}

/// The five state scopes, in order (docs/STATE_ARCHITECTURE.md): where a
/// field lives and who can read and write it.
///
/// - `ephemeral`: client memory, gone on reload.
/// - `local`: saved on the device (`.state/state.yaml`).
/// - `remote`: the user's own, saved on the backend and mirrored on the
///   client; local actions write it (synced up).
/// - `system`: backend only; only remote actions read or write it.
/// - `shared`: one copy on the backend, mirrored on every client; only
///   remote actions write it.
const stateScopes = ['ephemeral', 'local', 'remote', 'system', 'shared'];

/// The scopes the client's `State` has (no `system`).
const clientScopes = {'ephemeral', 'local', 'remote', 'shared'};

/// The scopes local actions emit (`StateDelta`).
const clientDeltaScopes = {'ephemeral', 'local', 'remote'};

/// The scopes remote actions read and emit.
const remoteScopes = {'remote', 'shared', 'system'};

/// Whether a `state:` map (app.yaml's, or state.yaml's) is split by scope:
/// every key is a scope and every value a map (or empty).
bool isScopedState(Map map) =>
    map.isNotEmpty &&
    map.keys.every((k) => stateScopes.contains(k.toString())) &&
    map.values.every((v) => v == null || v is Map);

/// A scoped `state:` map flattened into one map of fields, with each field's
/// scope in [scopes]. A field in two scopes is reported in [issues]. An
/// unscoped (flat) map is all `local`.
Map<String, dynamic> flattenState(Map map, Map<String, String> scopes,
    Issues issues, String file) {
  if (!isScopedState(map)) {
    for (final k in map.keys) {
      scopes[k.toString()] = 'local';
    }
    return {for (final e in map.entries) e.key.toString(): e.value};
  }
  final out = <String, dynamic>{};
  for (final scope in stateScopes) {
    final fields = map[scope];
    if (fields is! Map) continue;
    for (final e in fields.entries) {
      final key = e.key.toString();
      final other = scopes[key];
      if (other != null) {
        issues.error(file, 'state.$scope.$key',
            'is also in $other; field names are unique across scopes');
        continue;
      }
      scopes[key] = scope;
      out[key] = e.value;
    }
  }
  return out;
}

/// [models] with the `state` model reduced to the fields of [scopes]
/// (by [fieldScopes]).
Map<String, Model> stateModelsFor(Map<String, Model> models,
    Map<String, String> fieldScopes, Set<String> scopes) {
  final state = models[stateModelName];
  if (state is! ClassModel) return models;
  return {
    ...models,
    stateModelName: ClassModel(stateModelName, {
      for (final e in state.fields.entries)
        if (scopes.contains(fieldScopes[e.key] ?? 'local')) e.key: e.value,
    }),
  };
}

/// Validates one value against [type] (a remote field sent by a client).
void validateValue(dynamic value, TypeRef type, Map<String, Model> models,
        Issues issues, String path, {String file = 'value'}) =>
    _validateValue(value, type, models, issues, path, file);
