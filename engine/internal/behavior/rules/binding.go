package behaviorrules

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
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
	rows := uirules.RowWidgets(app.UI, app.Symbols)

	for _, b := range app.Behaviors {
		widget, address, event, ok := splitWidgetEvent(app, b.When)
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

		// The address is what names the action, not the prop: two buttons in
		// one row share onPressed and are two different things to do.
		action, err := ActionNameFor(widget, address, event)
		if err != nil {
			return fmt.Errorf("scenario %q: %w", b.ID, err)
		}

		key := widget + "." + address
		if i, seen := index[key]; seen {
			if bindings[i].Store != store {
				return fmt.Errorf("scenario %q: %s.%s already drives store %q, cannot also drive %q",
					b.ID, widget, address, bindings[i].Store, store)
			}
			bindings[i].ScenarioIDs = append(bindings[i].ScenarioIDs, b.ID)
			continue
		}

		index[key] = len(bindings)
		bindings = append(bindings, model.Binding{
			Widget:      widget,
			Param:       address,
			Event:       event,
			Store:       store,
			Action:      action,
			Indexed:     rows[widget],
			ScenarioIDs: []string{b.ID},
		})
	}

	app.Symbols.Bindings = bindings
	return nil
}

// widgetKindSuffixes are the naming suffixes a widget carries to say what it is
// rather than what it does. Stripping one leaves the verb. They are the last
// resort: see ActionNameFor.
var widgetKindSuffixes = []string{
	"Button", "Field", "Input", "Switch", "Checkbox", "Slider", "Tile", "Icon",
}

// ActionNameFor derives the store action a widget event runs.
//
// The spec answers first. Writing `onChanged: taskToggled` in ui.yaml names
// that event, and a name the author chose beats anything derived from the
// widget: taskCheckbox.taskToggled runs taskToggled, not task. A leading `on`
// is dropped, so `onPressed: onAddTask` runs addTask.
//
// Only a raw catalog prop leaves nothing to go on, and then the widget's name
// supplies the verb: incrementButton.onPressed runs increment.
//
// The name never comes from the values a scenario uses. See AGENTS.md, "The
// action a widget event runs comes from the spec".
func ActionNameFor(widget, address, prop string) (string, error) {
	if address != prop && address != "" {
		return lowerFirst(strings.TrimPrefix(address, "on")), nil
	}
	for _, suffix := range widgetKindSuffixes {
		if trimmed := strings.TrimSuffix(widget, suffix); trimmed != widget && trimmed != "" {
			return lowerFirst(trimmed), nil
		}
	}
	// No alias and no kind suffix to strip. Fall back to the prop, so that a
	// widget named for what it does rather than what it is still yields a
	// usable name.
	if verb := strings.TrimPrefix(prop, "on"); verb != prop && verb != "" {
		return lowerFirst(widget) + capitalizeFirst(verb), nil
	}
	return "", fmt.Errorf("cannot derive a store action from %q.%q: name the event in ui.yaml, e.g. %s: doSomething", widget, prop, prop)
}

// splitWidgetEvent reads back the widget, the name it answers to, and the prop
// that name fills.
//
// The answer is not in the text: `taskCheckbox.first.onChanged` names a row
// that is not part of the event, and `addTaskButton.onAddTask` names an alias
// that is not the prop. Resolution worked both out already and wrote them into
// the symbol table, so this reads them rather than parsing the string twice.
func splitWidgetEvent(app *model.App, ref string) (string, string, string, bool) {
	event, ok := app.Symbols.Events[ref]
	if !ok {
		return "", "", "", false
	}
	return event.Widget, event.Address, event.Event, true
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
