// Package order provides deterministic iteration over maps.
//
// Go randomizes map iteration order on every execution. Anywhere a map walk can
// reach generated code, warning text, or planned work, the walk must be ordered
// or the engine produces different bytes from identical specs. Reproducible
// output is what makes generated files reviewable in a diff and is a
// precondition for the lock/diff optimization.
//
// This package has no dependencies. It is safe to import from core and from any
// module.
package order

import "sort"

// Keys returns the keys of m sorted lexicographically.
func Keys[V any](m map[string]V) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
