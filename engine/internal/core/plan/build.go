package plan

import (
	"fmt"
	"sort"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/rules"
)

// Build analyzes the resolved IR and returns what to generate: which widgets
// need wrappers, and which scenarios need behaviorflutter.
//
// One scenario produces exactly one test. The planner does not decide which
// layer a scenario belongs to, and it does not emit work per store action per
// scenario. Working out "this failing test means that Cubit method" was the
// engine's job only because the repair stage asked about one file at a time; it
// now sees the whole app at once and does not need to be told.
func Build(app *model.App) (Work, error) {
	if app == nil {
		return Work{}, fmt.Errorf("ir is nil")
	}

	tests := make([]Test, 0, len(app.Behaviors))
	for _, scenario := range app.Behaviors {
		tests = append(tests, Test{ScenarioID: scenario.ID})
	}

	// One wrapper per widget that has something to wire, and a wrapper for
	// every page whether or not it does. A widget with a wrapper is reached by
	// its parent as a slot, so the wrappers nest the way the widgets do and
	// each one wires its own widget and nothing below it. See
	// uirules.WrapperWidgets.
	//
	// Every test pumps the page wrapper, because every scenario is a behavior
	// of the whole app, so a page wrapper exists even when no scenario names
	// the page.
	needsWrapper := uirules.WrapperWidgets(app)
	var wrappers []Wrapper
	for _, comp := range app.UI {
		if needsWrapper[comp.Name] || dart.IsPageName(comp.Name) {
			wrappers = append(wrappers, Wrapper{Widget: comp.Name})
		}
	}
	if !hasPage(wrappers) {
		if page := dart.FirstPageName(app.UI); page != "" {
			wrappers = append(wrappers, Wrapper{Widget: page})
		}
	}
	sort.Slice(wrappers, func(i, j int) bool { return wrappers[i].Widget < wrappers[j].Widget })

	return Work{Wrappers: wrappers, Tests: tests}, nil
}

// hasPage reports whether the planned wrappers already cover a page. Every run
// needs one, because that is what a test pumps.
func hasPage(wrappers []Wrapper) bool {
	for _, w := range wrappers {
		if dart.IsPageName(w.Widget) {
			return true
		}
	}
	return false
}
