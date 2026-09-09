package model

import "strings"

// Model is a declared shape from models.yaml: a name and the fields it holds.
type Model struct {
	Name   string
	Fields []Field
}

// Field is one field of a model. Type is the spec's own word: a primitive, the
// name of another model or enum, or `list(<type>)`.
type Field struct {
	Name     string
	Type     string
	Optional bool
}

// Enum is a declared closed set of values from models.yaml.
type Enum struct {
	Name   string
	Values []string
}

// Field returns the named field of a model.
func (m Model) Field(name string) (Field, bool) {
	for _, f := range m.Fields {
		if f.Name == name {
			return f, true
		}
	}
	return Field{}, false
}

// ModelNamed returns the declared model with this name.
func (app *App) ModelNamed(name string) (Model, bool) {
	for _, m := range app.Models {
		if m.Name == name {
			return m, true
		}
	}
	return Model{}, false
}

// ElementModel returns the model a store's list holds, if it holds one.
func (app *App) ElementModel(valueType string) (Model, bool) {
	inner, ok := ListElement(valueType)
	if !ok {
		return app.ModelNamed(valueType)
	}
	return app.ModelNamed(inner)
}

// ListElement reads the element type out of `list(task)`.
func ListElement(valueType string) (string, bool) {
	t := strings.TrimSpace(valueType)
	if !strings.HasPrefix(strings.ToLower(t), "list(") || !strings.HasSuffix(t, ")") {
		return "", false
	}
	return strings.TrimSpace(t[len("list(") : len(t)-1]), true
}
