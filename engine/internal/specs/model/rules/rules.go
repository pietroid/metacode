// Package modelrules interprets the model spec: the shapes a project's data
// takes, and the closed sets of values its fields can hold.
package modelrules

import (
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
)

// Primitives are the types every project has without declaring them.
var Primitives = map[string]bool{
	"string":   true,
	"boolean":  true,
	"bool":     true,
	"number":   true,
	"int":      true,
	"integer":  true,
	"double":   true,
	"datetime": true,
}

// Build reads models.yaml. A key whose value is a mapping declares a model, and
// a key whose value is a list declares an enum, which is the whole distinction
// the spec makes.
func Build(raw map[string]any) ([]model.Model, []model.Enum, error) {
	var models []model.Model
	var enums []model.Enum

	for _, name := range order.Keys(raw) {
		switch v := raw[name].(type) {
		case map[string]any:
			m, err := buildModel(name, v)
			if err != nil {
				return nil, nil, err
			}
			models = append(models, m)
		case []any:
			enums = append(enums, buildEnum(name, v))
		default:
			return nil, nil, fmt.Errorf("models.yaml > %s: expected fields or a list of values, got %T", name, raw[name])
		}
	}
	return models, enums, nil
}

func buildModel(name string, raw map[string]any) (model.Model, error) {
	m := model.Model{Name: name}
	for _, field := range order.Keys(raw) {
		declared, ok := raw[field].(string)
		if !ok {
			return model.Model{}, fmt.Errorf("models.yaml > %s.%s: expected a type name, got %T", name, field, raw[field])
		}
		// A trailing ? marks a field that need not be there.
		optional := strings.HasSuffix(declared, "?")
		m.Fields = append(m.Fields, model.Field{
			Name:     field,
			Type:     strings.TrimSuffix(declared, "?"),
			Optional: optional,
		})
	}
	return m, nil
}

func buildEnum(name string, raw []any) model.Enum {
	e := model.Enum{Name: name}
	for _, v := range raw {
		e.Values = append(e.Values, fmt.Sprintf("%v", v))
	}
	return e
}

// Register records every declared model and enum as a symbol, so a store or a
// field naming one resolves.
func Register(models []model.Model, enums []model.Enum, symbols *model.SymbolTable) {
	for _, m := range models {
		symbols.Register(m.Name, "model")
	}
	for _, e := range enums {
		symbols.Register(e.Name, "enum")
	}
}

// Validate checks that every field names a type that exists. A type that does
// not exist used to become `dynamic`, which compiles and then holds anything.
func Validate(models []model.Model, enums []model.Enum) []error {
	known := make(map[string]bool, len(models)+len(enums))
	for _, m := range models {
		known[m.Name] = true
	}
	for _, e := range enums {
		known[e.Name] = true
	}

	var errs []error
	for _, m := range models {
		for _, f := range m.Fields {
			if !IsKnownType(f.Type, known) {
				errs = append(errs, fmt.Errorf("models.yaml > %s.%s: unknown type %q", m.Name, f.Name, f.Type))
			}
		}
	}
	return errs
}

// IsKnownType reports whether a declared type names a primitive, a declared
// shape, or a list of either.
func IsKnownType(declared string, known map[string]bool) bool {
	if inner, ok := model.ListElement(declared); ok {
		return IsKnownType(inner, known)
	}
	return Primitives[strings.ToLower(declared)] || known[declared]
}
