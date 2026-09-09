package model

// UIComponent represents a declared widget from ui.yaml.
type UIComponent struct {
	Name      string
	Kind      string // catalog symbol or "custom"
	Props     map[string]any
	Children  []UIComponent
	Variables []Variable // bare unknown names discovered in this subtree
}

// TypeWidget is the variable type of a name that holds a widget. Every other
// type is the catalog's word for the prop the variable fills.
const TypeWidget = "widget"

// Variable is a bare name in the UI spec whose value is supplied later. Its
// type is the catalog's word for what the prop it fills holds, so a generator
// never has to guess: `value: taskDone` on a checkbox is a boolean, and
// `onChanged: taskToggled` is a callback.
type Variable struct {
	Name string
	Type string
	// Prop is the prop this variable fills, in the catalog's words. It is what
	// says that `onChanged: taskToggled` already handles the checkbox's
	// onChanged, so nothing has to declare a second parameter for it.
	Prop string
}

// UniqueVariables removes repeats, keeping the first occurrence and its order.
func UniqueVariables(vars []Variable) []Variable {
	seen := make(map[string]bool, len(vars))
	out := make([]Variable, 0, len(vars))
	for _, v := range vars {
		if seen[v.Name] {
			continue
		}
		seen[v.Name] = true
		out = append(out, v)
	}
	return out
}
