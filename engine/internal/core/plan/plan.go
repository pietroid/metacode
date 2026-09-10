// Package plan decides what a run will generate, from the resolved model
// alone.
//
// It names work, not files: "this page needs a wrapper", "this scenario needs
// a test". Where that lands on disk and what the class is called belongs to
// the target language, and is answered once in codegen/dart's layout rules.
// So the work is two lists of names, and every generator turns a name into a
// path the same way.
package plan

// Work is everything a run will generate, decided before anything is written.
type Work struct {
	// Wrappers names the widgets that need wiring to a store, sorted.
	Wrappers []string
	// Tests names the scenarios to verify, in spec order: exactly one test
	// each.
	Tests []string
}
