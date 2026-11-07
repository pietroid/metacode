/// The Metacode UI catalog: widget builders for everything ui.yaml can use.
///
/// - spec.dart: the contract (props, kinds, shorthands). Pure Dart.
/// - style.dart: the style.yaml tokens and the Metacode style. Pure Dart.
/// - src/theme.dart: tokens -> ThemeData, used by every builder.
/// - src/widgets/: one builder per widget.
/// - src/registry.dart: name -> builder.
library;

export 'spec.dart';
export 'src/parsers.dart';
export 'src/registry.dart';
export 'src/icons.dart' show phosphorIcons, phosphorNames;
export 'src/theme.dart';
export 'src/ui.dart';
