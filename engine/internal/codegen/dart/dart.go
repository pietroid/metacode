// Package dart is the toolkit for writing Dart source: where a generated file
// goes, what its classes are called, how a value becomes a literal, how a
// template is rendered to disk, how generated output is recognised and pruned,
// and what shape checks a file must pass before it is written.
//
// It is the layer below every codegen/flutter package. It knows Dart and the
// directory conventions this engine uses; it does not know what a spec is, and
// nothing in it depends on a spec module. Three packages used to hold these
// helpers — shared, codegen and codegen/dart — split along no line anyone could
// state, with the identifier check in one, the string escaping in another and
// the file marker in the third.
package dart
