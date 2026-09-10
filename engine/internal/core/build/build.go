// Package build turns raw specs into the model.
//
// It orchestrates and validates; it does not interpret. Each spec kind knows
// how to read itself — specs/data/rules reads stores, specs/ui/rules reads the
// widget tree, behavior/rules reads scenarios — and this package calls them in
// order and collects what they produce. Adding a spec kind is a rules package
// plus one call here.
//
// That interpretation used to live in the model package: 450 lines of YAML
// sugar rules for widgets and stores, in the one package that was supposed to
// know nothing about any particular spec.
package build

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/behavior/rules"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/order"
	"github.com/pietroid/metacode/engine/internal/specs/data/rules"
	"github.com/pietroid/metacode/engine/internal/specs/model/rules"
	"github.com/pietroid/metacode/engine/internal/specs/project/rules"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

// App converts raw specs into the model.
func App(raw spec.RawSpecs) (model.App, error) {
	app := model.App{Symbols: model.NewSymbolTable()}

	app.Warnings = append(app.Warnings, unknownKeys("project.yaml", raw.Project, []string{"name", "description"})...)
	app.Warnings = append(app.Warnings, unknownKeys("data.yaml", raw.Data, []string{"stores", "models", "enums"})...)
	app.Warnings = append(app.Warnings, unknownKeys("ui.yaml", raw.UI, []string{"widgets"})...)
	// behaviors.yaml top-level keys are user-defined scenario group names; do not warn.

	project, err := projectrules.Build(raw.Project)
	if err != nil {
		return model.App{}, fmt.Errorf("project: %w", err)
	}
	app.Project = project

	// Models are built before stores, because a store's value type names one.
	models, enums, err := modelrules.Build(raw.Models)
	if err != nil {
		return model.App{}, fmt.Errorf("models: %w", err)
	}
	app.Models = models
	app.Enums = enums
	modelrules.Register(models, enums, &app.Symbols)

	stores, err := datarules.Build(raw.Data)
	if err != nil {
		return model.App{}, fmt.Errorf("data: %w", err)
	}
	app.Stores = stores
	for _, store := range stores {
		app.Symbols.Register(store.Name, "store")
	}
	app.Warnings = append(app.Warnings, datarules.Warnings(raw.Data)...)

	// Widget names are registered before the tree is built, so a widget that
	// references a sibling resolves whatever order they are declared in.
	if err := uirules.RegisterWidgets(raw.UI, &app.Symbols); err != nil {
		return model.App{}, fmt.Errorf("register widgets: %w", err)
	}
	ui, err := uirules.Build(raw.UI, app.Symbols)
	if err != nil {
		return model.App{}, fmt.Errorf("ui: %w", err)
	}
	app.UI = ui

	behaviors, err := behaviorrules.BuildScenarios(raw.Behaviors)
	if err != nil {
		return model.App{}, fmt.Errorf("behaviors: %w", err)
	}
	app.Behaviors = behaviors

	return app, nil
}

// unknownKeys warns about top-level spec keys this engine does not read, so a
// typo in a spec file is reported rather than silently ignored.
func unknownKeys(file string, raw map[string]any, allowed []string) []string {
	allowedSet := make(map[string]bool, len(allowed))
	for _, key := range allowed {
		allowedSet[key] = true
	}
	var warnings []string
	for _, key := range order.Keys(raw) {
		if !allowedSet[key] {
			warnings = append(warnings, fmt.Sprintf("%s: unknown top-level key %q", file, key))
		}
	}
	return warnings
}
