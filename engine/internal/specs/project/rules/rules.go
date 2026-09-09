// Package project contains the interpretation and validation rules for the project spec.
package projectrules

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

// Validate checks the project spec for required fields.
func Validate(p model.Project) []error {
	var errs []error
	if strings.TrimSpace(p.Name) == "" {
		errs = append(errs, fmt.Errorf("project.yaml: missing name"))
	}
	return errs
}

// PackageName normalizes a project name into a valid Dart package name.
func PackageName(s string) string {
	if s == "" {
		return "unnamed_app"
	}
	var b strings.Builder
	for _, r := range strings.ToLower(s) {
		if unicode.IsLetter(r) || unicode.IsDigit(r) || r == '_' {
			b.WriteRune(r)
		} else if r == '-' || r == ' ' {
			b.WriteByte('_')
		}
	}
	name := b.String()
	name = strings.Trim(name, "_")
	if name == "" {
		return "unnamed_app"
	}
	first := rune(name[0])
	if !unicode.IsLetter(first) {
		name = "app_" + name
	}
	return name
}

// Build turns the project.yaml mapping into the project section of the model.
func Build(raw map[string]any) (model.Project, error) {
	p := model.Project{}
	if v, ok := raw["name"].(string); ok {
		p.Name = v
	}
	if v, ok := raw["description"].(string); ok {
		p.Description = v
	}
	return p, nil
}
