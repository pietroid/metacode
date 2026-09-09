package dart

import (
	"strings"
)

// UniqueStrings returns in with duplicates removed, preserving first-seen order.
func UniqueStrings(in []string) []string {
	seen := make(map[string]bool)
	var out []string
	for _, s := range in {
		if !seen[s] {
			seen[s] = true
			out = append(out, s)
		}
	}
	return out
}

// Indent prepends four spaces to every non-empty line of s.
func Indent(s string) string { return IndentBy(s, 4) }

// IndentBy prepends spaces spaces to every non-empty line of s.
func IndentBy(s string, spaces int) string {
	pad := strings.Repeat(" ", spaces)
	lines := strings.Split(s, "\n")
	for i, line := range lines {
		if line != "" {
			lines[i] = pad + line
		}
	}
	return strings.Join(lines, "\n")
}

// IndentLines indents every line of s except the first. Use it when the first
// line is placed after something else on its line, like a return statement.
func IndentLines(s string, spaces int) string {
	lines := strings.Split(s, "\n")
	for i := 1; i < len(lines); i++ {
		if lines[i] != "" {
			lines[i] = strings.Repeat(" ", spaces) + lines[i]
		}
	}
	return strings.Join(lines, "\n")
}
