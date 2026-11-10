// State as YAML: what the engine writes to `.state/*.yaml` (the client's and
// the backend's). Pure Dart, so the backend (bin/server.dart) uses it too.

import 'dart:convert';

import 'package:yaml/yaml.dart';

/// `<key>:` and [data] below it, as block YAML (`state:\n  count: 1`).
String yamlDocument(String key, Map data) =>
    data.isEmpty ? '$key: {}\n' : '$key:\n${toYaml(data)}\n';

/// The map under [key] in a document written by [yamlDocument], as plain
/// Dart; null when there is none or it doesn't parse.
Map<String, dynamic>? readYamlDocument(String? source, String key) {
  if (source == null) return null;
  try {
    final doc = plainYaml(loadYaml(source));
    final value = doc is Map ? doc[key] : null;
    return value is Map ? Map<String, dynamic>.from(value) : null;
  } catch (_) {
    return null;
  }
}

/// Parsed YAML nodes as plain Dart maps (String keys) and lists.
dynamic plainYaml(dynamic node) {
  if (node is Map) {
    return <String, dynamic>{
      for (final e in node.entries) e.key.toString(): plainYaml(e.value),
    };
  }
  if (node is List) return [for (final v in node) plainYaml(v)];
  return node;
}

/// [value] as block YAML at [indent], nested lists and maps at any depth
/// (a list of models whose fields are lists, like a recipe's tags).
/// Empty lists and maps are written inline (`[]`, `{}`), never as a bare
/// `key:`, which would read back as null.
String toYaml(dynamic value, {int indent = 1}) {
  final prefix = '  ' * indent;
  bool isBlock(dynamic v) =>
      (v is Map && v.isNotEmpty) || (v is List && v.isNotEmpty);
  if (value is Map) {
    return value.entries.map((e) {
      final v = e.value;
      if (isBlock(v)) {
        return '$prefix${e.key}:\n${toYaml(v, indent: indent + 1)}';
      }
      return '$prefix${e.key}: ${_scalarYaml(v)}';
    }).join('\n');
  }
  if (value is List) {
    return value.map((item) {
      if (isBlock(item)) {
        // The item's own block one level deeper, its first line after
        // the dash: `- name: x` then `  tags:` aligned under `name`.
        final block = toYaml(item, indent: indent + 1);
        return '$prefix- ${block.substring(prefix.length + 2)}';
      }
      return '$prefix- ${_scalarYaml(item)}';
    }).join('\n');
  }
  return '$prefix${_scalarYaml(value)}';
}

/// A value written on one line: an empty list or map, or a scalar.
String _scalarYaml(dynamic value) {
  if (value is List) return '[]';
  if (value is Map) return '{}';
  return _escapeYaml(value);
}

/// Strings are always written as JSON strings (valid YAML), so a string
/// that looks like a number, a bool or a date ("10", "true") reads back as
/// a string.
String _escapeYaml(dynamic value) {
  if (value == null) return 'null';
  if (value is bool) return value ? 'true' : 'false';
  if (value is num) return value.toString();
  return jsonEncode(value.toString());
}
