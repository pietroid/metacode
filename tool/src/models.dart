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

/// Validates the models (every file in models/, merged).
Map<String, Model> parseModels(dynamic doc, Issues issues) {
  const file = 'models/';
  final models = <String, Model>{};

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
        _checkResolves(field.value, models, issues, '${model.name}.${field.key}');
      }
    }
  }

  final state = models[stateModelName];
  if (state == null) {
    issues.error(file, '',
        'missing the reserved "$stateModelName" model that types state.yaml');
  } else if (state is! ClassModel) {
    issues.error(file, stateModelName, 'must be a model (map of fields), not an enum');
  }

  return models;
}

void _checkResolves(
    TypeRef type, Map<String, Model> models, Issues issues, String path) {
  if (type.isList) {
    _checkResolves(type.item!, models, issues, path);
  } else if (!primitives.containsKey(type.name) &&
      !models.containsKey(type.name)) {
    issues.error('models/', path, 'unknown type "${type.name}"');
  }
}

/// Validates the merged `state` map (state/) against the reserved `state` model.
void validateState(dynamic doc, Map<String, Model> models, Issues issues) {
  const file = 'state/';
  final stateModel = models[stateModelName];
  if (stateModel is! ClassModel) return;

  if (doc is! Map || doc['state'] is! Map) {
    issues.error(file, '', 'must contain a top-level "state:" map');
    return;
  }
  _validateValue(doc['state'], const TypeRef(stateModelName), models, issues,
      'state');
}

void _validateValue(dynamic value, TypeRef type, Map<String, Model> models,
    Issues issues, String path) {
  const file = 'state/';
  void fail(String message) => issues.error(file, path, message);

  if (value == null) {
    if (!type.optional) fail('is required ($type)');
    return;
  }

  if (type.isList) {
    if (value is! List) return fail('expected a list ($type)');
    for (var i = 0; i < value.length; i++) {
      _validateValue(value[i], type.item!, models, issues, '$path[$i]');
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
          if (!model.fields.containsKey(key.toString())) {
            issues.error(file, '$path.$key', 'not a field of ${model.name}');
          }
        }
        for (final field in model.fields.entries) {
          _validateValue(value[field.key], field.value, models, issues,
              '$path.${field.key}');
        }
      }
  }
}
