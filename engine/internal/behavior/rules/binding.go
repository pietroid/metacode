package behaviorrules

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

// ResolveBindings derives one binding per widget event that changes a store.
// Scenarios that share a widget event share a binding, because they describe
// the same action under different preconditions.
//
// The specs never name the action: they name the widget, the event, and the
// store field the scenario expects to change. Resolving that link once, here,
// is what keeps the store generator, the wrapper generator and the test
// generator from each inventing their own answer.
func ResolveBindings(app *model.App) error {
	index := make(map[string]int)
	var bindings []model.Binding

	for _, b := range app.Behaviors {
		widget, event, ok := splitWidgetEvent(app, b.When)
		if !ok {
			continue
		}
		if b.Then == nil {
			continue
		}
		store, field := model.SplitRef(b.Then.Target)
		if field == "" {
			continue
		}
		if sym, ok := app.Symbols.Lookup(store); !ok || sym.Kind != "store" {
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
		bindings = append(bindings, model.Binding{
			Widget:      widget,
			Event:       event,
			Store:       store,
			Action:      action,
			ScenarioIDs: []string{b.ID},
		})
	}

	app.Symbols.Bindings = bindings
	return nil
}

// widgetKindSuffixes are the naming suffixes a widget carries to say what it is
// rather than what it does. Stripping one leaves the verb.
var widgetKindSuffixes = []string{
	"Button", "Field", "Input", "Switch", "Checkbox", "Slider", "Tile", "Icon",
}

// ActionNameFor derives the store action a widget event runs from the widget's
// name: decrementButton.onPressed becomes decrement, saveButton.onPressed
// becomes save.
//
// The name comes from the spec, never from the values a scenario uses. See
// docs/decisions.md, "The action a widget event runs comes from the spec".
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
func splitWidgetEvent(app *model.App, ref string) (string, string, bool) {
	root, member := model.SplitRef(ref)
	if member == "" {
		return "", "", false
	}
	if sym, ok := app.Symbols.Lookup(root); !ok || sym.Kind != "widget" {
		return "", "", false
	}
	return root, member, true
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
