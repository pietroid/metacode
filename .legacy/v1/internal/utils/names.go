package utils

import (
	"strings"
	"unicode"
)

// ToLowerCamel converts a snake/kebab/Pascal string to lowerCamelCase.
func ToLowerCamel(s string) string {
	parts := splitWords(s)
	if len(parts) == 0 {
		return ""
	}
	b := strings.Builder{}
	b.WriteString(strings.ToLower(parts[0]))
	for _, p := range parts[1:] {
		b.WriteString(strings.Title(p))
	}
	return b.String()
}

// ToUpperCamel converts a snake/kebab/lower string to UpperCamelCase.
func ToUpperCamel(s string) string {
	parts := splitWords(s)
	b := strings.Builder{}
	for _, p := range parts {
		b.WriteString(strings.Title(p))
	}
	return b.String()
}

// ToSnakeCase converts a Camel/Pascal/kebab string to snake_case.
func ToSnakeCase(s string) string {
	parts := splitWords(s)
	for i := range parts {
		parts[i] = strings.ToLower(parts[i])
	}
	return strings.Join(parts, "_")
}

// splitWords splits a string into words separated by underscores, hyphens,
// or camelCase boundaries.
func splitWords(s string) []string {
	var words []string
	var current strings.Builder
	var prev rune
	for i, r := range s {
		if r == '_' || r == '-' || r == ' ' {
			if current.Len() > 0 {
				words = append(words, current.String())
				current.Reset()
			}
			prev = r
			continue
		}
		if i > 0 && unicode.IsUpper(r) && unicode.IsLower(prev) {
			words = append(words, current.String())
			current.Reset()
		}
		current.WriteRune(r)
		prev = r
	}
	if current.Len() > 0 {
		words = append(words, current.String())
	}
	return words
}

// TitleCase returns the string with the first letter uppercased.
func TitleCase(s string) string {
	if s == "" {
		return ""
	}
	return strings.ToUpper(s[:1]) + s[1:]
}

// LowerFirst returns the string with the first letter lowercased.
func LowerFirst(s string) string {
	if s == "" {
		return ""
	}
	return strings.ToLower(s[:1]) + s[1:]
}
