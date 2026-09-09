// Package planner decides what a run will generate, from the resolved IR
// alone.
//
// It names work, not files: "this page needs a wrapper", "this scenario needs a
// test". Where that lands on disk and what the class is called belongs to the
// target language, and is answered once in codegen/dart's layout rules.
package plan

// Plan is everything a run will generate, decided before anything is written.
type Work struct {
	// Wrappers are the widgets that need wiring to a store, in a stable order.
	Wrappers []Wrapper
	// Tests are the scenarios to verify: exactly one test per scenario, in
	// spec order.
	Tests []Test
}

// Wrapper is one widget whose events or bindings have to reach a store.
type Wrapper struct {
	Widget string
}

// Test is one behavior scenario, verified against the whole app.
type Test struct {
	ScenarioID string
}

// Widgets lists the wrapped widget names, in plan order.
func (w Work) Widgets() []string {
	out := make([]string, 0, len(w.Wrappers))
	for _, w := range w.Wrappers {
		out = append(out, w.Widget)
	}
	return out
}
