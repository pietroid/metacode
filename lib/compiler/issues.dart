/// Collects validation problems so the tool can report all of them at once.
///
/// [scoped] returns a view that shares the same lists and prefixes file
/// names with an app's folder (`modules/food/`), so nested apps report
/// paths relative to `examples/my_own_app/`.
class Issues {
  final List<String> errors;
  final List<String> warnings;
  final String prefix;

  Issues() : errors = [], warnings = [], prefix = '';
  Issues._(this.errors, this.warnings, this.prefix);

  Issues scoped(String folder) => Issues._(errors, warnings, '$prefix$folder');

  void error(String file, String path, String message) =>
      errors.add(_format('$prefix$file', path, message));

  void warn(String file, String path, String message) =>
      warnings.add(_format('$prefix$file', path, message));

  bool get hasErrors => errors.isNotEmpty;

  static String _format(String file, String path, String message) =>
      path.isEmpty ? '$file: $message' : '$file > $path: $message';
}

const dartKeywords = {
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
  'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
  'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
  'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
  'return', 'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync',
  'this', 'throw', 'true', 'try', 'type', 'typedef', 'var', 'void', 'when',
  'while', 'with', 'yield',
};

final identifier = RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$');

bool isValidName(String name) =>
    identifier.hasMatch(name) && !dartKeywords.contains(name);

/// `thisCase` (keys, functions, models, label keys).
final camelCase = RegExp(r'^[a-z][a-zA-Z0-9]*$');

/// `ThisCase` (pages and components).
final pascalCase = RegExp(r'^[A-Z][a-zA-Z0-9]*$');

/// The file name for a name: `exampleSlide` / `ExampleSlide` -> `example_slide`,
/// `step1State` -> `step_1_state`.
String snakeCase(String name) => name
    .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => '_${m[1]}')
    .replaceAllMapped(RegExp(r'(?<=[A-Za-z])([0-9]+)'), (m) => '_${m[1]}')
    .toLowerCase();

/// The base name of [file] without its extension: `app/views/a/b_c.yaml` -> `b_c`.
String baseName(String file) {
  final name = file.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot < 0 ? name : name.substring(0, dot);
}
