package plan

import (
	"fmt"
	"sort"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
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

	// One wrapper per page, and only per page. A page's generated widget takes
	// a callback parameter for every event of every widget it embeds, so one
	// wrapper at the top wires the whole screen. A wrapper per button was
	// written too, and then referenced by nothing: the page could not use it,
	// because the page instantiates its children itself.
	//
	// Every test pumps the page wrapper, because every scenario is a behavior
	// of the whole app, so a page wrapper exists even when no scenario names
	// the page.
	var wrappers []Wrapper
	for _, comp := range app.UI {
		if dart.IsPageName(comp.Name) {
			wrappers = append(wrappers, Wrapper{Widget: comp.Name})
		}
	}
	if len(wrappers) == 0 {
		if page := dart.FirstPageName(app.UI); page != "" {
			wrappers = append(wrappers, Wrapper{Widget: page})
		}
	}
	sort.Slice(wrappers, func(i, j int) bool { return wrappers[i].Widget < wrappers[j].Widget })

	return Work{Wrappers: wrappers, Tests: tests}, nil
}
