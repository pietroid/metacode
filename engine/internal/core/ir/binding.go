package ir

import (
	"fmt"
	"strings"
	"unicode"
)

// Binding is the resolved link between a widget event and the store action it
// triggers: "pressing decrementButton runs counterStore.decrement".
//
// The specs never name the action. They name the widget, the event, and the
// store field the scenario expects to change. Resolving that link once, here,
// is what keeps the store generator, the wrapper generator, and the test
// generator from each inventing their own answer.
type Binding struct {
	Widget      string   // decrementButton
	Event       string   // onPressed
	Store       string   // counterStore
	Action      string   // decrement
	ScenarioIDs []string // every scenario that exercises this binding
}

// FullPath is the widget event that triggers the binding.
func (b Binding) FullPath() string { return b.Widget + "." + b.Event }

// resolveBindings derives one Binding per widget event that changes a store.
// Scenarios that share a widget event share a binding, because they describe
// the same action under different preconditions.
func (ir *IR) resolveBindings() error {
	index := make(map[string]int)
	var bindings []Binding

	for _, b := range ir.Behaviors {
		widget, event, ok := ir.splitWidgetEvent(b.When)
		if !ok {
			continue
		}
		if b.Then == nil {
			continue
		}
		store, field := splitPath(b.Then.Target)
		if field == "" {
			continue
		}
		if sym, ok := ir.Symbols.Lookup(store); !ok || sym.Kind != "store" {
			// The scenario asserts on something other than a store, e.g. a
			// widget variable. There is no action to resolve.
			continue
		}

		action, err := ActionNameFor(widget, event)
		if err != nil {
			return fmt.Errorf("scenario %q: %w", b.ID, err)
		}

		key := widget + "." + event
		if i, seen := index[key]; seen {
			if bindings[i].Store != store {
				return fmt.Errorf("scenario %q: %s.%s already drives store %q, cannot also drive %q",
					b.ID, widget, event, bindings[i].Store, store)
			}
			bindings[i].ScenarioIDs = append(bindings[i].ScenarioIDs, b.ID)
			continue
		}

		index[key] = len(bindings)
		bindings = append(bindings, Binding{
			Widget:      widget,
			Event:       event,
			Store:       store,
			Action:      action,
			ScenarioIDs: []string{b.ID},
		})
	}

	ir.Symbols.Bindings = bindings
	return nil
}

// BindingFor returns the binding for a widget event, if there is one.
func (st SymbolTable) BindingFor(widget, event string) (Binding, bool) {
	for _, b := range st.Bindings {
		if b.Widget == widget && b.Event == event {
			return b, true
		}
	}
	return Binding{}, false
}

// BindingsForStore returns every binding that drives the named store, in
// declaration order.
func (st SymbolTable) BindingsForStore(store string) []Binding {
	var out []Binding
	for _, b := range st.Bindings {
		if b.Store == store {
			out = append(out, b)
		}
	}
	return out
}

// widgetKindSuffixes are the naming suffixes a widget carries to say what it is
// rather than what it does. Stripping one leaves the verb.
var widgetKindSuffixes = []string{
	"Button", "Field", "Input", "Switch", "Checkbox", "Slider", "Tile", "Icon",
}

// ActionNameFor derives the store action a widget event runs, from the widget's
// name: decrementButton.onPressed becomes decrement, saveButton.onPressed
// becomes save.
//
// The name comes from the spec rather than from the shape of the values a
// scenario happens to use. Guessing it from arithmetic, as this engine used to,
// works only for counters and silently mislabels everything else.
func ActionNameFor(widget, event string) (string, error) {
	for _, suffix := range widgetKindSuffixes {
		if trimmed := strings.TrimSuffix(widget, suffix); trimmed != widget && trimmed != "" {
			return lowerFirst(trimmed), nil
		}
	}
	// No kind suffix to strip. Fall back to the event, so that a widget named
	// for what it does rather than what it is still yields a usable name.
	if verb := strings.TrimPrefix(event, "on"); verb != event && verb != "" {
		return lowerFirst(widget) + capitalizeFirst(verb), nil
	}
	return "", fmt.Errorf("cannot derive a store action from %q.%q: name the widget after what it does, e.g. %sButton", widget, event, widget)
}

// splitWidgetEvent splits "widget.event" when the root resolves to a widget.
func (ir *IR) splitWidgetEvent(ref string) (string, string, bool) {
	root, member := splitPath(ref)
	if member == "" {
		return "", "", false
	}
	if sym, ok := ir.Symbols.Lookup(root); !ok || sym.Kind != "widget" {
		return "", "", false
	}
	return root, member, true
}

// splitPath splits a dotted reference into its first segment and the rest.
func splitPath(ref string) (string, string) {
	parts := strings.SplitN(ref, ".", 2)
	if len(parts) != 2 {
		return ref, ""
	}
	return parts[0], parts[1]
}

func lowerFirst(s string) string {
	if s == "" {
		return ""
	}
	r := []rune(s)
	r[0] = unicode.ToLower(r[0])
	return string(r)
}

func capitalizeFirst(s string) string {
	if s == "" {
		return ""
	}
	r := []rune(s)
	r[0] = unicode.ToUpper(r[0])
	return string(r)
}
