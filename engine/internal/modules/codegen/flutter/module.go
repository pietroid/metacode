// Package flutter is the concrete code-generation module for Flutter projects.
//
// It lives under internal/modules/ to keep target-specific generation rules
// separate from the spec-agnostic engine core. The actual generation logic is
// split into per-concern sub-packages (project, data, ui) under their
// codegen/flutter directories; this package orchestrates them.
package flutter

// Module identifies this concrete module for logging and dispatch.
const Module = "flutter"
