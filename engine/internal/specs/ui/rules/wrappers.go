package uirules

import (
	"github.com/pietroid/metacode/engine/internal/core/model"
)

// WrapperWidgets names every widget that gets a wrapper of its own: one that
// declares a variable, or has an event a behavior binds to a store action.
//
// A widget with nothing to wire is embedded by its parent as it always was. A
// widget that does have something to wire is reached through its own wrapper,
// so the shape of the tree stays in the generated widgets and only the wiring
// is written per widget. See docs/decisions.md, "A widget that needs wiring is
// reached through its own wrapper".
//
// It is a rule about the UI spec rather than a planning decision, because two
// stages have to agree on it before there is a plan: the widget generator asks
// it to decide which children become slots, and the planner asks it to decide
// which wrappers to write.
func WrapperWidgets(app *model.App) map[string]bool {
	if app == nil {
		return nil
	}

	out := make(map[string]bool)
	for _, comp := range app.UI {
		if len(model.UniqueVariables(comp.Variables)) > 0 {
			out[comp.Name] = true
		}
	}
	for _, event := range app.Symbols.Events {
		if _, ok := app.Symbols.Widgets[event.Widget]; ok {
			out[event.Widget] = true
		}
	}
	return out
}
