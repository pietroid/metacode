/// Collects validation problems so the tool can report all of them at once.
///
/// [scoped] returns a view that shares the same lists and prefixes file
/// names with an app's folder (`apps/food/`), so nested apps report
/// paths relative to `metacode/`.
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
