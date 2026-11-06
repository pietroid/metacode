/// The Metacode UI catalog: widget builders for everything ui.yaml can use.
///
/// - spec.dart: the contract (props, kinds, shorthands). Pure Dart.
/// - src/widgets/: one builder per widget.
/// - src/registry.dart: name -> builder.
library;

export 'spec.dart';
export 'src/parsers.dart';
export 'src/registry.dart';
export 'src/ui.dart';
