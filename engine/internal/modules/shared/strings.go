package shared

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
func Indent(s string) string {
	lines := strings.Split(s, "\n")
	for i, line := range lines {
		if line != "" {
			lines[i] = "    " + line
		}
	}
	return strings.Join(lines, "\n")
}

// IsVariableIdentifier reports whether s looks like a lowerCamel variable name.
func IsVariableIdentifier(s string) bool {
	if s == "" {
		return false
	}
	runes := []rune(s)
	first := runes[0]
	if !(first >= 'a' && first <= 'z') {
		return false
	}
	for _, r := range runes[1:] {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '_' {
			continue
		}
		return false
	}
	return true
}
