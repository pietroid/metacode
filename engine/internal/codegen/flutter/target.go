// Package flutter assembles the Flutter target: it is the only package that
// knows generating a Flutter project means a project step, then stores, then
// widgets, then wrappers, then tests, in that order.
//
// The per-spec generators live with their spec (specs/<kind>/codegen/flutter,
// behavior/codegen/flutter) and the Dart toolkit below them all is codegen/dart.
// This package is what puts them in order, and adding a second language means
// writing a sibling of it.
package flutter

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/behavior/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
	"github.com/pietroid/metacode/engine/internal/specs/data/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/specs/model/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/specs/project/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/specs/ui/codegen/flutter"
)

// GenerateAll runs the full Flutter generation pipeline for the given IR.
// It scaffolds the project, generates stores, and generates widgets.
func GenerateAll(app *model.App, outDir string) error {
	if err := projectflutter.Generate(app, outDir); err != nil {
		return fmt.Errorf("project generation: %w", err)
	}
	if err := modelflutter.Generate(app, outDir); err != nil {
		return fmt.Errorf("model generation: %w", err)
	}
	if err := dataflutter.Generate(app, outDir); err != nil {
		return fmt.Errorf("store generation: %w", err)
	}
	if err := uiflutter.Generate(app, catalog.Default(), outDir); err != nil {
		return fmt.Errorf("widget generation: %w", err)
	}
	return nil
}

// GenerateWrappers writes the wrapper layer that wires widgets to Cubits.
// Wrappers are scaffolded from the IR so the project compiles, and the
// implement stage rewrites them together with the stores in a single request.
func GenerateWrappers(app *model.App, work plan.Work, outDir string) error {
	return behaviorflutter.GenerateWrappers(app, work, outDir)
}

// GenerateTests emits one widget test per planned scenario.
func GenerateTests(app *model.App, work plan.Work, outDir string) error {
	return behaviorflutter.GenerateTests(app, work, outDir)
}
