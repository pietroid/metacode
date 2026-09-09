package dart

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

// PascalCase converts a lowerCamel or snake_case identifier to PascalCase.
func PascalCase(s string) string {
	if s == "" {
		return ""
	}
	var b strings.Builder
	upper := true
	for _, r := range s {
		if r == '_' || r == '-' || r == ' ' {
			upper = true
			continue
		}
		if upper {
			b.WriteRune(unicode.ToUpper(r))
			upper = false
		} else {
			b.WriteRune(r)
		}
	}
	return b.String()
}

// SnakeCase converts a camelCase identifier to snake_case.
func SnakeCase(s string) string {
	if s == "" {
		return ""
	}
	var b strings.Builder
	for i, r := range s {
		if unicode.IsUpper(r) {
			if i > 0 {
				b.WriteByte('_')
			}
			b.WriteRune(unicode.ToLower(r))
		} else {
			b.WriteRune(r)
		}
	}
	return b.String()
}

// StoreBaseName strips a trailing "Store" suffix (case-insensitive) from a
// store symbol name so that counterStore becomes counter.
func StoreBaseName(s string) string {
	if strings.HasSuffix(strings.ToLower(s), "store") {
		return strings.TrimSuffix(s, "Store")
	}
	return s
}

// IsPageName reports whether name follows the page naming convention.
func IsPageName(name string) bool {
	if strings.EqualFold(name, "homePage") {
		return true
	}
	return strings.HasSuffix(name, "Page")
}

// FirstPageName selects the symbol to use as the application's home page.
// It prefers a component named "homePage" (case-insensitive) or one whose name
// ends with "Page", falling back to the first declared component.
func FirstPageName(ui []model.UIComponent) string {
	if len(ui) == 0 {
		return ""
	}
	for _, c := range ui {
		if strings.EqualFold(c.Name, "homePage") {
			return c.Name
		}
	}
	for _, c := range ui {
		if strings.HasSuffix(c.Name, "Page") {
			return c.Name
		}
	}
	return ui[0].Name
}

// DartStringLiteral returns a single-quoted Dart string literal for v.
func DartStringLiteral(v string) string {
	return fmt.Sprintf("'%s'", strings.ReplaceAll(v, "'", "\\'"))
}

// FindComponent returns the UI component with the given name or nil.
func FindComponent(components []model.UIComponent, name string) *model.UIComponent {
	for i := range components {
		if components[i].Name == name {
			return &components[i]
		}
	}
	return nil
}
