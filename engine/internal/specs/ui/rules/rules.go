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

	allowed := make(map[string]bool, len(sym.Props)+1)
	allowed[sym.DefaultProp] = true
	for _, p := range sym.Props {
		allowed[p.Name] = true
	}

	for _, prop := range order.Keys(comp.Props) {
		if !allowed[prop] {
			errs = append(errs, fmt.Errorf("ui.yaml > %s: prop %q is not allowed for %s", comp.Name, prop, comp.Kind))
			continue
		}
		if prop == catalog.PropIcon {
			errs = append(errs, validateIcon(comp, comp.Props[prop], c)...)
		}
	}
	errs = append(errs, validateList(comp)...)
	if sym.DefaultProp == catalog.PropIcon {
		if _, ok := comp.Props[catalog.PropIcon]; !ok {
			// The renderer used to substitute Icons.add here, so a button that
			// forgot to say which icon it was silently became a plus sign.
			errs = append(errs, fmt.Errorf("ui.yaml > %s: %s must name an icon, as in `icon: %sadd`", comp.Name, comp.Kind, catalog.IconPrefix))
		}
	}

	for _, child := range comp.Children {
		errs = append(errs, validateComponent(child, c)...)
	}
	return errs
}

// validateIcon checks an icon value against the icon vocabulary. An icon is
// named, never bound, so an unqualified value is rejected rather than quietly
// treated as a variable and rendered as text.
func validateIcon(comp model.UIComponent, val any, c *catalog.Catalog) []error {
	name, ok := val.(string)
	if !ok {
		return nil
	}
	if !catalog.IsIconRef(name) {
		return []error{fmt.Errorf("ui.yaml > %s: icon %q must name the icon vocabulary, as in `icon: %sadd`", comp.Name, name, catalog.IconPrefix)}
	}
	if _, ok := c.FindIcon(name); !ok {
		return []error{fmt.Errorf("ui.yaml > %s: unknown icon %q (see specification/base_specs/ui_catalog.md)", comp.Name, name)}
	}
	return nil
}

// validateList checks the two forms of a list against each other. A list is
// static or dynamic, never both and never half of one: a `items` with no `item`
// used to render as an empty ListView, which looks like a list with nothing in
// it rather than like a spec missing a line.
func validateList(comp model.UIComponent) []error {
	_, hasItems := comp.Props[catalog.PropItems]
	_, hasItem := comp.Props[catalog.PropItem]
	_, hasChildren := comp.Props[catalog.PropChildren]

	switch {
	case hasItems && hasChildren:
		return []error{fmt.Errorf("ui.yaml > %s: a list is static (`children`) or dynamic (`items` and `item`), not both", comp.Name)}
	case hasItems && !hasItem:
		return []error{fmt.Errorf("ui.yaml > %s: `items` needs an `item` saying what one element renders as", comp.Name)}
	case hasItem && !hasItems:
		return []error{fmt.Errorf("ui.yaml > %s: `item` needs an `items` saying what it renders one of", comp.Name)}
	}
	return nil
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
		if len(raw) == 0 {
			return nil, nil
		}
		// A ui.yaml that declares widgets at the top level used to build zero
		// widgets and say nothing, so every later stage reported the widget it
		// could not find rather than the one line that was missing.
		return nil, fmt.Errorf("ui.yaml has no `widgets:` key; every widget is declared under it")
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
	prop := defaultContentProp(comp.Kind)
	comp.Props[prop] = value
	if isVariableReference(value, symbols) {
		comp.Variables = append(comp.Variables, variableAt(comp.Kind, prop, value))
	}
}

// variableAt names a variable together with what the prop it fills holds. It is
// the whole answer to "what type is this": the catalog knows, so nothing
// downstream has to assume.
func variableAt(kind, prop, name string) model.Variable {
	return model.Variable{Name: name, Type: VariableType(catalog.Default().PropType(kind, prop)), Prop: prop}
}

// VariableType maps a prop type to the type of a variable filling it. A widget
// prop given a bare name renders it as text, which is why both report text; a
// behavior can still say the variable holds a widget.
func VariableType(t catalog.PropType) string {
	switch {
	case t.IsCallback():
		return string(t)
	case t.IsWidget(), t == catalog.TypeText:
		return string(catalog.TypeText)
	default:
		return string(t)
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
			comp.Variables = append(comp.Variables, model.Variable{Name: v, Type: string(catalog.TypeText)})
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
		if err := applyProp(comp, key, raw[key], symbols); err != nil {
			return err
		}
	}
	return nil
}

func applyProp(comp *model.UIComponent, key string, val any, symbols model.SymbolTable) error {
	comp.Props[key] = val
	switch key {
	case catalog.PropChild:
		return applyChildProp(comp, val, symbols)
	case catalog.PropChildren:
		list, ok := val.([]any)
		if !ok {
			return fmt.Errorf("children must be a list")
		}
		for _, item := range list {
			if err := appendChild(comp, item, symbols); err != nil {
				return err
			}
		}
		return nil
	default:
		if isNestedWidget(comp.Kind, key) {
			// `expanded: {listView: ...}` is the nested mapping form: the inner
			// widget is this one's content, not a prop named after it. Without
			// this it became a prop, which validation then rejected by name.
			delete(comp.Props, key)
			return appendChild(comp, map[string]any{key: val}, symbols)
		}
		if s, ok := val.(string); ok && isVariableReference(s, symbols) {
			comp.Variables = append(comp.Variables, variableAt(comp.Kind, key, s))
			return nil
		}
		// Recursively scan nested structures for additional variables.
		scanVariables(comp.Kind, val, symbols, &comp.Variables)
		return nil
	}
}

// isNestedWidget reports whether key, appearing under a widget of the given
// kind, names a widget rather than one of that kind's props.
func isNestedWidget(kind, key string) bool {
	c := catalog.Default()
	return c.IsKnown(key) && !c.AllowsProp(kind, key)
}

func applyChildProp(comp *model.UIComponent, val any, symbols model.SymbolTable) error {
	if s, ok := val.(string); ok {
		if isVariableReference(s, symbols) {
			comp.Variables = append(comp.Variables, variableAt(comp.Kind, catalog.PropChild, s))
		}
		return nil
	}
	return appendChild(comp, val, symbols)
}

func appendChild(comp *model.UIComponent, raw any, symbols model.SymbolTable) error {
	child, err := buildChildComponent(raw, symbols)
	if err != nil {
		return err
	}
	comp.Children = append(comp.Children, child)
	comp.Variables = append(comp.Variables, child.Variables...)
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

// scanVariables walks a prop value that was left raw, such as the nested
// mapping under `body:`, and collects the variables inside it. It carries the
// widget kind it is currently inside so a variable still gets the type of the
// prop it fills: a key that names a catalog widget becomes the new kind, and
// any other key is a prop of the current one.
func scanVariables(kind string, raw any, symbols model.SymbolTable, out *[]model.Variable) {
	switch v := raw.(type) {
	case string:
		if isVariableReference(v, symbols) {
			*out = append(*out, variableAt(kind, defaultContentProp(kind), v))
		}
	case []any:
		for _, item := range v {
			scanVariables(kind, item, symbols, out)
		}
	case map[string]any:
		for _, key := range order.Keys(v) {
			if catalog.Default().IsKnown(key) {
				scanVariables(key, v[key], symbols, out)
				continue
			}
			if s, ok := v[key].(string); ok && isVariableReference(s, symbols) {
				*out = append(*out, variableAt(kind, key, s))
				continue
			}
			scanVariables(kind, v[key], symbols, out)
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
