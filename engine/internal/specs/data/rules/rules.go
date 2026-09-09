// Package datarules interprets and validates the data spec: it reads the
// stores a project declares and checks each one carries what a generator needs.
package datarules

import (
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
)

// Validate checks that every store has the minimum required fields.
func Validate(stores []model.Store) []error {
	var errs []error
	for _, s := range stores {
		if s.ValueType == "" {
			errs = append(errs, fmt.Errorf("data.yaml > %s: missing value type", s.Name))
		}
	}
	return errs
}

// SupportedStoreCount is how many stores the generators can wire today. The
// wrapper, the tests and lib/app.dart each provide and read exactly one Cubit.
const SupportedStoreCount = 1

// CheckSupported reports a spec this engine cannot generate from yet.
//
// It is an error, not a warning, and it is stated once here rather than left
// implied by three generators reading stores[0]: a second store used to be
// parsed, registered as a symbol, and then silently dropped, so a spec author
// got an app that ignored half their data spec with nothing in the log about it.
func CheckSupported(stores []model.Store) error {
	if len(stores) > SupportedStoreCount {
		names := make([]string, 0, len(stores))
		for _, s := range stores {
			names = append(names, s.Name)
		}
		return fmt.Errorf("data.yaml declares %d stores (%s) but this engine generates for %d today (see todo/27-multi-store-support)",
			len(stores), strings.Join(names, ", "), SupportedStoreCount)
	}
	return nil
}

// Build turns the data.yaml mapping into the stores of the model.
func Build(raw map[string]any) ([]model.Store, error) {
	var stores []model.Store

	storesRaw, _ := raw["stores"].(map[string]any)
	for _, name := range order.Keys(storesRaw) {
		cfg, ok := storesRaw[name].(map[string]any)
		if !ok {
			return nil, fmt.Errorf("store %q: expected mapping", name)
		}
		store := model.Store{Name: name, Strategy: "ephemeral"}
		if v, ok := cfg["value"].(string); ok {
			store.ValueType = v
		}
		if v, ok := cfg["initialValue"]; ok {
			store.InitialValue = v
		}
		if v, ok := cfg["strategy"].(string); ok {
			store.Strategy = v
		}
		stores = append(stores, store)
	}

	return stores, nil
}

// undeclaredSupport warns about spec sections the engine parses but does not
// generate from yet. Carrying a half-built representation of them in the IR,
// as this package used to for models and enums, gave every reader the
// impression they were supported.
// Warnings reports spec sections this engine parses but cannot generate from
// yet.
func Warnings(rawData map[string]any) []string {
	var warnings []string
	for _, section := range []struct{ key, todo string }{
		{"models", "todo/20-model-spec-support"},
		{"enums", "todo/20-model-spec-support"},
	} {
		if declared, ok := rawData[section.key].(map[string]any); ok && len(declared) > 0 {
			warnings = append(warnings, fmt.Sprintf(
				"data.yaml: %d %s are declared but not generated yet (see %s)",
				len(declared), section.key, section.todo))
		}
	}
	return warnings
}
