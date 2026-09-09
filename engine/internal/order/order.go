// Package order provides deterministic iteration over maps.
//
// Anywhere a map walk can reach generated code, warning text or planned work,
// the walk must be ordered: see docs/decisions.md, "Map iteration is sorted
// everywhere it can reach output".
//
// It has no dependencies and is safe to import from anywhere in the tree.
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
