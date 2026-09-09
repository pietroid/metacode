package uirules

import (
	"sort"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/order"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

// RowWidgets names every widget that is rendered once per element of a list:
// the widget a listView's `item` names, and everything that widget embeds.
//
// They need to know which row they are. Their key carries the index, because a
// key is how a test finds a widget and N rows sharing one key is both an
// ambiguous finder and a duplicate-key error at runtime.
func RowWidgets(components []model.UIComponent, symbols model.SymbolTable) map[string]bool {
	out := make(map[string]bool)
	for _, comp := range components {
		for _, name := range ItemBuilders(comp) {
			out[name] = true
		}
	}
	// A row's children are rendered once per row too, so they are rows as well.
	for changed := true; changed; {
		changed = false
		for name := range out {
			for _, ref := range ReferencedWidgets(symbols.Widgets[name], symbols) {
				if !out[ref] {
					out[ref] = true
					changed = true
				}
			}
		}
	}
	return out
}

// itemBuilderParams lists the row builders this widget needs, named after the
// widget each list builds one of.
func ItemBuilders(comp model.UIComponent) []string {
	var out []string
	var walk func(model.UIComponent)
	walk = func(c model.UIComponent) {
		if _, ok := c.Props[catalog.PropItems]; ok {
			if item, ok := c.Props[catalog.PropItem].(string); ok {
				out = append(out, item)
			}
		}
		for _, child := range c.Children {
			walk(child)
		}
	}
	walk(comp)
	return uniqueStrings(out)
}

// referencedWidgets lists the declared widgets that comp embeds, sorted.
func ReferencedWidgets(comp model.UIComponent, symbols model.SymbolTable) []string {
	refs := make(map[string]bool)
	collectWidgetRefs(comp, comp.Name, symbols, refs)
	collectRawWidgetRefs(comp.Props, comp.Name, symbols, refs)

	// A row widget is named by this widget but built by its wrapper, so it is
	// not embedded here and importing it would leave an unused import.
	for _, name := range ItemBuilders(comp) {
		delete(refs, name)
	}

	out := make([]string, 0, len(refs))
	for name := range refs {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}
func collectRawWidgetRefs(raw any, self string, symbols model.SymbolTable, refs map[string]bool) {
	switch v := raw.(type) {
	case string:
		if v != self {
			if sym, ok := symbols.Lookup(v); ok && sym.Kind == "widget" {
				refs[v] = true
			}
		}
	case map[string]any:
		for _, key := range order.Keys(v) {
			if key != self {
				if sym, ok := symbols.Lookup(key); ok && sym.Kind == "widget" {
					refs[key] = true
				}
			}
			collectRawWidgetRefs(v[key], self, symbols, refs)
		}
	case []any:
		for _, item := range v {
			collectRawWidgetRefs(item, self, symbols, refs)
		}
	}
}
func collectWidgetRefs(comp model.UIComponent, self string, symbols model.SymbolTable, refs map[string]bool) {
	if comp.Name != self {
		if sym, ok := symbols.Lookup(comp.Name); ok && sym.Kind == "widget" {
			refs[comp.Name] = true
		}
	}
	for _, child := range comp.Children {
		collectWidgetRefs(child, self, symbols, refs)
	}
}

// uniqueStrings removes repeats, keeping the first occurrence and its order.
func uniqueStrings(in []string) []string {
	seen := make(map[string]bool, len(in))
	out := make([]string, 0, len(in))
	for _, s := range in {
		if seen[s] {
			continue
		}
		seen[s] = true
		out = append(out, s)
	}
	return out
}
