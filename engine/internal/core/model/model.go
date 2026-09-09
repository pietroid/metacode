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
	Models    []Model
	Enums     []Enum
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

// Row selectors address one element of a list, in a behavior target and in the
// widget a list builds one of per element.
const (
	RowFirst = "first"
	RowLast  = "last"
)

// CountMember asks how many rows a widget rendered; LengthMember asks how long
// a stored list is.
const (
	CountMember  = "count"
	LengthMember = "length"
)

// Ref is a dotted path written in a behavior: a root that names a store or a
// widget, then the members reached from it. A row selector is one of those
// members, which is what lets `taskTile.first.taskTitle` and
// `taskStore.value.first.done` be the same shape of thing.
type Ref struct {
	Root    string
	Members []string
}

// ParseRef splits a dotted path. It does no validation: what a shape is allowed
// to be belongs to symbol resolution, which is the stage that knows what the
// root is.
func ParseRef(s string) Ref {
	parts := strings.Split(s, ".")
	return Ref{Root: parts[0], Members: parts[1:]}
}

// IsRowSelector reports whether a member addresses one element of a list.
func IsRowSelector(member string) bool {
	return member == RowFirst || member == RowLast
}

// RowSelector returns the row this ref addresses, and whether it addresses one.
func (r Ref) RowSelector() (string, bool) {
	for _, m := range r.Members {
		if IsRowSelector(m) {
			return m, true
		}
	}
	return "", false
}

// Last returns the final member, or "" when the ref names only its root.
func (r Ref) Last() string {
	if len(r.Members) == 0 {
		return ""
	}
	return r.Members[len(r.Members)-1]
}
