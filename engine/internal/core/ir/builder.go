// Package ir builds the typed internal representation from raw specs.
//
// It is part of the engine core and defines the domain objects (project, stores,
// UI components, behaviors, symbols) that all code-generation modules consume.
package ir

import (
	"fmt"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/order"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

// Build converts raw specs into the internal representation.
func Build(raw spec.RawSpecs) (IR, error) {
	ir := IR{
		Symbols: NewSymbolTable(),
	}

	ir.Warnings = append(ir.Warnings, unknownKeys("project.yaml", raw.Project, []string{"name", "description"})...)
	ir.Warnings = append(ir.Warnings, unknownKeys("data.yaml", raw.Data, []string{"stores", "models", "enums"})...)
	ir.Warnings = append(ir.Warnings, unknownKeys("ui.yaml", raw.UI, []string{"widgets"})...)
	// behaviors.yaml top-level keys are user-defined scenario group names; do not warn.

	project, err := buildProject(raw.Project)
	if err != nil {
		return IR{}, fmt.Errorf("project: %w", err)
	}
	ir.Project = project

	stores, models, enums, err := buildData(raw.Data)
	if err != nil {
		return IR{}, fmt.Errorf("data: %w", err)
	}
	ir.Stores = stores
	ir.Models = models
	ir.Enums = enums
	for _, s := range stores {
		ir.Symbols.Register(s.Name, "store")
	}
	for _, m := range models {
		ir.Symbols.Register(m.Name, "model")
	}
	for _, e := range enums {
		ir.Symbols.Register(e.Name, "enum")
	}

	if err := preRegisterWidgets(raw.UI, &ir.Symbols); err != nil {
		return IR{}, fmt.Errorf("register widgets: %w", err)
	}
	ui, err := buildUI(raw.UI, ir.Symbols)
	if err != nil {
		return IR{}, fmt.Errorf("ui: %w", err)
	}
	ir.UI = ui

	behaviors, err := buildBehaviors(raw.Behaviors)
	if err != nil {
		return IR{}, fmt.Errorf("behaviors: %w", err)
	}
	ir.Behaviors = behaviors

	return ir, nil
}

func unknownKeys(file string, raw map[string]any, allowed []string) []string {
	allowedSet := make(map[string]bool, len(allowed))
	for _, k := range allowed {
		allowedSet[k] = true
	}
	var warnings []string
	for _, key := range order.Keys(raw) {
		if !allowedSet[key] {
			warnings = append(warnings, fmt.Sprintf("%s: unknown top-level key %q", file, key))
		}
	}
	return warnings
}

func buildProject(raw map[string]any) (Project, error) {
	p := Project{}
	if v, ok := raw["name"].(string); ok {
		p.Name = v
	}
	if v, ok := raw["description"].(string); ok {
		p.Description = v
	}
	return p, nil
}

func buildData(raw map[string]any) ([]Store, []Model, []Enum, error) {
	var stores []Store
	var models []Model
	var enums []Enum

	storesRaw, _ := raw["stores"].(map[string]any)
	for _, name := range order.Keys(storesRaw) {
		val := storesRaw[name]
		cfg, ok := val.(map[string]any)
		if !ok {
			return nil, nil, nil, fmt.Errorf("store %q: expected mapping", name)
		}
		store := Store{Name: name, Strategy: "ephemeral"}
		if v, ok := cfg["value"].(string); ok {
			store.ValueType = v
		}
		if v, ok := cfg["initialValue"]; ok {
			store.InitialValue = v
		}
		if v, ok := cfg["strategy"].(string); ok {
			store.Strategy = v
		}
		stores = append(stores, store)
	}

	modelsRaw, _ := raw["models"].(map[string]any)
	for _, name := range order.Keys(modelsRaw) {
		val := modelsRaw[name]
		m := Model{Name: name, Fields: make(map[string]string)}
		if fields, ok := val.(map[string]any); ok {
			for fieldName, fieldVal := range fields {
				if fv, ok := fieldVal.(string); ok {
					m.Fields[fieldName] = fv
				}
			}
		}
		models = append(models, m)
	}

	enumsRaw, _ := raw["enums"].(map[string]any)
	for _, name := range order.Keys(enumsRaw) {
		val := enumsRaw[name]
		e := Enum{Name: name}
		if values, ok := val.([]any); ok {
			for _, v := range values {
				if s, ok := v.(string); ok {
					e.Values = append(e.Values, s)
				}
			}
		}
		enums = append(enums, e)
	}

	return stores, models, enums, nil
}

func preRegisterWidgets(raw map[string]any, symbols *SymbolTable) error {
	widgetsRaw, _ := raw["widgets"].(map[string]any)
	for name := range widgetsRaw {
		symbols.Register(name, "widget")
	}
	return nil
}

func buildUI(raw map[string]any, symbols SymbolTable) ([]UIComponent, error) {
	widgetsRaw, _ := raw["widgets"].(map[string]any)
	if widgetsRaw == nil {
		return nil, nil
	}

	var components []UIComponent
	for _, name := range order.Keys(widgetsRaw) {
		comp, err := buildComponent(name, widgetsRaw[name], symbols)
		if err != nil {
			return nil, fmt.Errorf("widget %q: %w", name, err)
		}
		components = append(components, comp)
	}
	return components, nil
}

// buildComponent converts a single widget declaration into a UIComponent.
// The name argument is the symbol key from the parent (e.g. "text", "counterButton").
func buildComponent(name string, raw any, symbols SymbolTable) (UIComponent, error) {
	comp := UIComponent{
		Name:  name,
		Kind:  classifyKind(name, symbols),
		Props: make(map[string]any),
	}

	switch v := raw.(type) {
	case string:
		// Syntax sugar: kind is the symbol name; value is the default content.
		prop := defaultContentProp(comp.Kind)
		comp.Props[prop] = v
		if isVariableReference(v, symbols) {
			comp.Variables = append(comp.Variables, v)
		}
	case []any:
		// Syntax sugar: a list becomes the children prop.
		comp.Props["children"] = v
		for _, item := range v {
			child, err := buildChildComponent(item, symbols)
			if err != nil {
				return UIComponent{}, err
			}
			comp.Children = append(comp.Children, child)
			comp.Variables = append(comp.Variables, child.Variables...)
		}
	case map[string]any:
		if comp.Kind == name && catalog.New().IsKnown(name) {
			// The key itself is the catalog symbol; value is a map of props.
			if err := applyProps(&comp, v, symbols); err != nil {
				return UIComponent{}, err
			}
		} else {
			// The key names a custom/widget symbol; the value is a map whose
			// single key is the actual catalog kind, e.g. counterButton: {elevatedButton: ...}.
			kind, rest, err := extractSingleKind(v, symbols)
			if err != nil {
				return UIComponent{}, err
			}
			comp.Kind = kind
			if err := applyProps(&comp, rest, symbols); err != nil {
				return UIComponent{}, err
			}
		}
	default:
		return UIComponent{}, fmt.Errorf("unexpected widget value type %T", raw)
	}

	return comp, nil
}

// buildChildComponent converts a value that appears inside a child/children list.
func buildChildComponent(raw any, symbols SymbolTable) (UIComponent, error) {
	switch v := raw.(type) {
	case string:
		// A bare string inside a list is a widget reference or variable.
		kind := classifyKind(v, symbols)
		comp := UIComponent{Name: v, Kind: kind, Props: make(map[string]any)}
		if kind == "variable" {
			comp.Variables = append(comp.Variables, v)
		}
		return comp, nil
	case map[string]any:
		if len(v) != 1 {
			return UIComponent{}, fmt.Errorf("nested widget mapping must have exactly one key, got %d", len(v))
		}
		for name, val := range v {
			return buildComponent(name, val, symbols)
		}
	default:
		return UIComponent{}, fmt.Errorf("unsupported child component type %T", raw)
	}
	return UIComponent{}, fmt.Errorf("unsupported child component type %T", raw)
}

func applyProps(comp *UIComponent, raw map[string]any, symbols SymbolTable) error {
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
func extractSingleKind(m map[string]any, symbols SymbolTable) (string, map[string]any, error) {
	cat := catalog.New()
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
	if s, ok := catalog.New().Find(kind); ok {
		return s.DefaultProp
	}
	return catalog.PropChild
}

func classifyKind(name string, symbols SymbolTable) string {
	if catalog.New().IsKnown(name) {
		return name
	}
	if sym, ok := symbols.Lookup(name); ok {
		return sym.Kind
	}
	return "variable"
}

func isVariableReference(name string, symbols SymbolTable) bool {
	return isLowerCamelIdentifier(name) && !catalog.New().IsKnown(name) && !isRegisteredSymbol(name, symbols)
}

func isRegisteredSymbol(name string, symbols SymbolTable) bool {
	_, ok := symbols.Lookup(name)
	return ok
}

func scanVariables(raw any, symbols SymbolTable, out *[]string) {
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

func isLowerCamelIdentifier(s string) bool {
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

func buildBehaviors(raw map[string]any) ([]BehaviorScenario, error) {
	var scenarios []BehaviorScenario
	for _, group := range order.Keys(raw) {
		if err := appendBehaviorScenarios(group, raw[group], nil, &scenarios); err != nil {
			return nil, err
		}
	}
	return scenarios, nil
}

func appendBehaviorScenarios(key string, raw any, path []string, out *[]BehaviorScenario) error {
	switch v := raw.(type) {
	case map[string]any:
		if looksLikeScenario(v) {
			id := strings.Join(append(append([]string(nil), path...), key), "/")
			scenario, err := ParseBehaviorScenario(
				id,
				key,
				path,
				stringValue(v, "given"),
				stringValue(v, "when"),
				stringValue(v, "then"),
			)
			if err != nil {
				return err
			}
			*out = append(*out, scenario)
			return nil
		}
		// Copy rather than append in place: sibling recursive calls each append
		// to newPath, and a shared backing array would let them overwrite each
		// other's group path.
		newPath := append(append([]string(nil), path...), key)
		for _, k := range order.Keys(v) {
			if err := appendBehaviorScenarios(k, v[k], newPath, out); err != nil {
				return err
			}
		}
	case []any:
		for _, item := range v {
			if err := appendBehaviorScenarios(key, item, path, out); err != nil {
				return err
			}
		}
	}
	return nil
}

func looksLikeScenario(m map[string]any) bool {
	_, hasWhen := m["when"]
	_, hasThen := m["then"]
	return hasWhen || hasThen
}

func stringValue(m map[string]any, key string) string {
	if v, ok := m[key].(string); ok {
		return v
	}
	return ""
}
