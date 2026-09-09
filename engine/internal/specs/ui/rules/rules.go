// Package ui contains the interpretation and validation rules for the UI spec.
package uirules

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

// Validate checks every UI component against the UI catalog and reports
// problems such as unknown props. Custom widgets are not validated here.
func Validate(components []model.UIComponent, c *catalog.Catalog) []error {
	var errs []error
	for _, comp := range components {
		errs = append(errs, validateComponent(comp, c)...)
	}
	return errs
}

func validateComponent(comp model.UIComponent, c *catalog.Catalog) []error {
	var errs []error
	sym, ok := c.Find(comp.Kind)
	if !ok {
		// Custom widgets are validated by symbol resolution, not the catalog.
		return errs
	}

	allowed := make(map[string]bool, len(sym.AllowedProps)+1)
	allowed[sym.DefaultProp] = true
	for _, p := range sym.AllowedProps {
		allowed[p] = true
	}

	for prop := range comp.Props {
		if !allowed[prop] {
			errs = append(errs, fmt.Errorf("ui.yaml > %s: prop %q is not allowed for %s", comp.Name, prop, comp.Kind))
		}
	}

	for _, child := range comp.Children {
		errs = append(errs, validateComponent(child, c)...)
	}
	return errs
}

// RegisterWidgets records every declared widget name before the tree is built,
// so a widget that references a sibling resolves whatever order they appear in.
func RegisterWidgets(raw map[string]any, symbols *model.SymbolTable) error {
	widgetsRaw, _ := raw["widgets"].(map[string]any)
	for name := range widgetsRaw {
		symbols.Register(name, "widget")
	}
	return nil
}

// Build turns the ui.yaml mapping into the widget tree of the model.
func Build(raw map[string]any, symbols model.SymbolTable) ([]model.UIComponent, error) {
	widgetsRaw, _ := raw["widgets"].(map[string]any)
	if widgetsRaw == nil {
		return nil, nil
	}

	var components []model.UIComponent
	for _, name := range order.Keys(widgetsRaw) {
		comp, err := buildComponent(name, widgetsRaw[name], symbols)
		if err != nil {
			return nil, fmt.Errorf("widget %q: %w", name, err)
		}
		components = append(components, comp)
	}
	return components, nil
}

// buildComponent converts one widget declaration into a component.
//
// The UI spec has exactly three sugar rules, and this is where they are stated:
//
//	text: "Hello"          a scalar is the widget's default prop
//	column: [a, b]         a list is the widget's children
//	myButton: {button: …}  a mapping is either props, or a kind plus its props
//
// The name argument is the key the parent declared this node under — a catalog
// symbol like "text", or a widget name like "incrementButton".
func buildComponent(name string, raw any, symbols model.SymbolTable) (model.UIComponent, error) {
	comp := model.UIComponent{
		Name:  name,
		Kind:  classifyKind(name, symbols),
		Props: make(map[string]any),
	}

	switch v := raw.(type) {
	case string:
		applyScalarSugar(&comp, v, symbols)
		return comp, nil
	case []any:
		return comp, applyChildrenSugar(&comp, v, symbols)
	case map[string]any:
		return comp, applyMapping(&comp, name, v, symbols)
	default:
		return model.UIComponent{}, fmt.Errorf("unexpected widget value type %T", raw)
	}
}

// applyScalarSugar handles `text: "Hello"`: the value is the widget's default
// prop, and it is a variable reference when it names no known symbol.
func applyScalarSugar(comp *model.UIComponent, value string, symbols model.SymbolTable) {
	comp.Props[defaultContentProp(comp.Kind)] = value
	if isVariableReference(value, symbols) {
		comp.Variables = append(comp.Variables, value)
	}
}

// applyChildrenSugar handles `column: [a, b]`: the list is the children.
func applyChildrenSugar(comp *model.UIComponent, items []any, symbols model.SymbolTable) error {
	comp.Props[catalog.PropChildren] = items
	for _, item := range items {
		child, err := buildChildComponent(item, symbols)
		if err != nil {
			return err
		}
		comp.Children = append(comp.Children, child)
		comp.Variables = append(comp.Variables, child.Variables...)
	}
	return nil
}

// applyMapping handles a mapping value, which means one of two things: the key
// is itself a catalog widget and the mapping is its props, or the key names a
// widget of this project and the mapping says which catalog widget it is —
// `incrementButton: {elevatedButton: {…}}`.
func applyMapping(comp *model.UIComponent, name string, raw map[string]any, symbols model.SymbolTable) error {
	if comp.Kind == name && catalog.Default().IsKnown(name) {
		return applyProps(comp, raw, symbols)
	}

	kind, props, err := extractSingleKind(raw, symbols)
	if err != nil {
		return err
	}
	comp.Kind = kind
	return applyProps(comp, props, symbols)
}

// buildChildComponent converts a value that appears inside a child/children list.
func buildChildComponent(raw any, symbols model.SymbolTable) (model.UIComponent, error) {
	switch v := raw.(type) {
	case string:
		// A bare string inside a list is a widget reference or variable.
		kind := classifyKind(v, symbols)
		comp := model.UIComponent{Name: v, Kind: kind, Props: make(map[string]any)}
		if kind == "variable" {
			comp.Variables = append(comp.Variables, v)
		}
		return comp, nil
	case map[string]any:
		if len(v) != 1 {
			return model.UIComponent{}, fmt.Errorf("nested widget mapping must have exactly one key, got %d", len(v))
		}
		for name, val := range v {
			return buildComponent(name, val, symbols)
		}
	default:
		return model.UIComponent{}, fmt.Errorf("unsupported child component type %T", raw)
	}
	return model.UIComponent{}, fmt.Errorf("unsupported child component type %T", raw)
}

func applyProps(comp *model.UIComponent, raw map[string]any, symbols model.SymbolTable) error {
	for _, key := range order.Keys(raw) {
		val := raw[key]
		if key == "child" {
			comp.Props[key] = val
			if s, ok := val.(string); ok {
				if isVariableReference(s, symbols) {
					comp.Variables = append(comp.Variables, s)
				}
			} else {
				child, err := buildChildComponent(val, symbols)
				if err != nil {
					return err
				}
				comp.Children = append(comp.Children, child)
				comp.Variables = append(comp.Variables, child.Variables...)
			}
		} else if key == "children" {
			comp.Props[key] = val
			list, ok := val.([]any)
			if !ok {
				return fmt.Errorf("children must be a list")
			}
			for _, item := range list {
				child, err := buildChildComponent(item, symbols)
				if err != nil {
					return err
				}
				comp.Children = append(comp.Children, child)
				comp.Variables = append(comp.Variables, child.Variables...)
			}
		} else {
			comp.Props[key] = val
			if s, ok := val.(string); ok && isVariableReference(s, symbols) {
				comp.Variables = append(comp.Variables, s)
			}
			// Recursively scan nested structures for additional variables.
			scanVariables(val, symbols, &comp.Variables)
		}
	}
	return nil
}

// extractSingleKind resolves the catalog kind for a widget declared as
// `name: {kind: ...}`.
//
// Keys are walked in sorted order and a catalog symbol wins over any other key,
// so the result does not depend on map iteration order when the mapping has
// more than one key.
func extractSingleKind(m map[string]any, symbols model.SymbolTable) (string, map[string]any, error) {
	cat := catalog.Default()
	keys := order.Keys(m)

	for _, key := range keys {
		if cat.IsKnown(key) {
			return key, propsFor(key, m[key]), nil
		}
	}

	for _, key := range keys {
		// A declared widget key is a reference wrapper: the component renders
		// as that widget and carries no props of its own.
		if sym, ok := symbols.Lookup(key); ok && sym.Kind == "widget" {
			return key, map[string]any{}, nil
		}
	}

	for _, key := range keys {
		return key, propsFor(key, m[key]), nil
	}
	return "custom", map[string]any{}, nil
}

// propsFor normalizes a widget value into a prop mapping, applying the
// default-content sugar when the value is not already a mapping.
func propsFor(kind string, val any) map[string]any {
	if rest, ok := val.(map[string]any); ok {
		return rest
	}
	return map[string]any{defaultContentProp(kind): val}
}

func defaultContentProp(kind string) string {
	if s, ok := catalog.Default().Find(kind); ok {
		return s.DefaultProp
	}
	return catalog.PropChild
}

func classifyKind(name string, symbols model.SymbolTable) string {
	if catalog.Default().IsKnown(name) {
		return name
	}
	if sym, ok := symbols.Lookup(name); ok {
		return sym.Kind
	}
	return "variable"
}

func isVariableReference(name string, symbols model.SymbolTable) bool {
	return IsVariableIdentifier(name) && !catalog.Default().IsKnown(name) && !isRegisteredSymbol(name, symbols)
}

func isRegisteredSymbol(name string, symbols model.SymbolTable) bool {
	_, ok := symbols.Lookup(name)
	return ok
}

func scanVariables(raw any, symbols model.SymbolTable, out *[]string) {
	switch v := raw.(type) {
	case string:
		if isVariableReference(v, symbols) {
			*out = append(*out, v)
		}
	case []any:
		for _, item := range v {
			scanVariables(item, symbols, out)
		}
	case map[string]any:
		for _, key := range order.Keys(v) {
			scanVariables(v[key], symbols, out)
		}
	}
}

// IsVariableIdentifier reports whether s is a lowerCamel identifier, which is
// the syntax the specs use for a variable name.
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
