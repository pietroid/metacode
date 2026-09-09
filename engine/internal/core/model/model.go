// Package model is the engine's internal representation: the domain objects
// every later stage reads — the project, its stores, its widgets, its behavior
// scenarios, and the symbols and bindings resolved between them.
//
// It is deliberately the leaf of the tree. Each spec kind's rules package fills
// its own slice of the App, so those packages import this one; if the building
// lived here too, this package would have to import them back.
package model

import "strings"

// App is the single internal representation produced from the raw specs.
type App struct {
	Project   Project
	Stores    []Store
	UI        []UIComponent
	Behaviors []BehaviorScenario
	Symbols   SymbolTable
	Warnings  []string
}

// ScenarioByID returns the scenario with the given ID. Three packages used to
// carry their own copy of this loop.
func (app *App) ScenarioByID(id string) (BehaviorScenario, bool) {
	for _, s := range app.Behaviors {
		if s.ID == id {
			return s, true
		}
	}
	return BehaviorScenario{}, false
}

// SplitRef splits a dotted spec reference at the first dot: "counterStore.value"
// becomes "counterStore" and "value". The second result is empty when the
// reference has no dot.
func SplitRef(s string) (string, string) {
	parts := strings.SplitN(s, ".", 2)
	if len(parts) != 2 {
		return s, ""
	}
	return parts[0], parts[1]
}
