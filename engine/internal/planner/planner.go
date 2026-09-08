package planner

import (
	"fmt"
	"sort"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/data"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
)

// Plan analyzes the resolved IR and returns an ordered list of generation tasks:
// which wrappers exist, and which tests exist.
//
// One scenario produces exactly one test task. The planner does not decide
// which layer a scenario belongs to, and it no longer emits a task per store
// action per scenario. Working out "this failing test means that Cubit method"
// was the engine's job only because the repair stage asked about one file at a
// time; it now sees the whole app at once and does not need to be told.
func Plan(app *ir.IR) ([]Task, error) {
	if app == nil {
		return nil, fmt.Errorf("ir is nil")
	}

	wrappers := make(map[string]Task)
	tests := make([]Task, 0, len(app.Behaviors))

	for _, scenario := range app.Behaviors {
		if err := planScenario(app, scenario, wrappers, &tests); err != nil {
			return nil, err
		}
	}

	// Every test pumps the page wrapper, because every scenario is a behavior
	// of the whole app. So the page wrapper always exists, even when no
	// scenario happens to name the page: without this, an app whose scenarios
	// only mention buttons generated tests importing a wrapper that was never
	// written.
	if task, ok := buildPageWrapperTask(app); ok {
		if _, exists := wrappers[task.ID]; !exists {
			wrappers[task.ID] = task
		}
	}

	ordered := make([]Task, 0, len(wrappers)+len(tests))
	for _, id := range sortedKeys(wrappers) {
		ordered = append(ordered, wrappers[id])
	}
	ordered = append(ordered, tests...)
	return ordered, nil
}

// buildPageWrapperTask returns the wrapper task for the app's page.
func buildPageWrapperTask(app *ir.IR) (Task, bool) {
	pageName := shared.FirstPageName(app.UI)
	if pageName == "" {
		return Task{}, false
	}

	ctx := strings.Builder{}
	ctx.WriteString(fmt.Sprintf("Widget: %s\n", pageName))
	ctx.WriteString("This is the page every scenario test pumps.\n")

	return Task{
		ID:              fmt.Sprintf("wrapper-%s-page", shared.SnakeCase(pageName)),
		Type:            TaskWrapper,
		Widget:          pageName,
		TargetFile:      fmt.Sprintf("lib/wrappers/%s_wrapper.dart", shared.SnakeCase(pageName)),
		Description:     fmt.Sprintf("Wire the page %q", pageName),
		PromptContext:   ctx.String(),
		ExpectedOutcome: fmt.Sprintf("%s composes the app and every scenario test can pump it", pageName),
	}, true
}

func planScenario(app *ir.IR, scenario ir.BehaviorScenario, wrappers map[string]Task, tests *[]Task) error {
	// Test task: every scenario gets one.
	*tests = append(*tests, buildTestTask(app, scenario))

	// Wrapper task derived from the widget side of the scenario.
	if scenario.Then != nil {
		if task, ok := buildWidgetWrapperTask(app, scenario, scenario.Then.Target); ok {
			wrappers[task.ID] = task
		}
	}
	if scenario.When != "" {
		if task, ok := buildWidgetWrapperTask(app, scenario, scenario.When); ok {
			wrappers[task.ID] = task
		}
	}

	return nil
}

// buildWidgetWrapperTask creates a wrapper task when target references a widget
// field or event. Store-only targets produce no wrapper task.
func buildWidgetWrapperTask(app *ir.IR, scenario ir.BehaviorScenario, target string) (Task, bool) {
	parts := strings.SplitN(target, ".", 2)
	if len(parts) != 2 {
		return Task{}, false
	}
	root, member := parts[0], parts[1]

	sym, ok := app.Symbols.Lookup(root)
	if !ok || sym.Kind != "widget" {
		return Task{}, false
	}

	widget, ok := app.Symbols.Widgets[root]
	if !ok {
		return Task{}, false
	}

	id := fmt.Sprintf("wrapper-%s-%s", shared.SnakeCase(root), shared.SnakeCase(member))
	targetFile := fmt.Sprintf("lib/wrappers/%s_wrapper.dart", shared.SnakeCase(root))

	description := fmt.Sprintf("Wire widget %q so that %s satisfies scenario %q", root, member, scenario.ID)

	ctx := strings.Builder{}
	ctx.WriteString(fmt.Sprintf("Scenario ID: %s\n", scenario.ID))
	ctx.WriteString(fmt.Sprintf("Description: %s\n", scenario.Description))
	if scenario.Given != nil {
		ctx.WriteString(fmt.Sprintf("Given: %s %s %s\n", scenario.Given.Target, scenario.Given.Op, scenario.Given.Value))
	}
	ctx.WriteString(fmt.Sprintf("When: %s\n", scenario.When))
	if scenario.Then != nil {
		ctx.WriteString(fmt.Sprintf("Then: %s %s %s\n", scenario.Then.Target, scenario.Then.Op, scenario.Then.Value))
	}
	ctx.WriteString(fmt.Sprintf("Widget: %s (kind: %s)\n", widget.Name, widget.Kind))
	ctx.WriteString(fmt.Sprintf("Member: %s\n", member))

	// Mention the relevant store wiring inferred from the scenario.
	if storeRef, action := inferStoreAction(app, scenario); storeRef != "" {
		ctx.WriteString(fmt.Sprintf("Store action: %s.%s\n", storeRef, action))
	}
	if storeRef, field := inferStoreField(app, scenario); storeRef != "" {
		ctx.WriteString(fmt.Sprintf("Store field: %s.%s\n", storeRef, field))
	}

	expected := fmt.Sprintf("%s.%s is wired so the scenario %q passes", root, member, scenario.ID)

	return Task{
		ID:              id,
		Type:            TaskWrapper,
		Widget:          root,
		TargetFile:      targetFile,
		ScenarioID:      scenario.ID,
		Description:     description,
		PromptContext:   ctx.String(),
		ExpectedOutcome: expected,
	}, true
}

func buildTestTask(app *ir.IR, scenario ir.BehaviorScenario) Task {
	ctx := strings.Builder{}
	ctx.WriteString(fmt.Sprintf("Scenario ID: %s\n", scenario.ID))
	ctx.WriteString(fmt.Sprintf("Description: %s\n", scenario.Description))
	if scenario.Given != nil {
		ctx.WriteString(fmt.Sprintf("Given: %s %s %s\n", scenario.Given.Target, scenario.Given.Op, scenario.Given.Value))
	}
	ctx.WriteString(fmt.Sprintf("When: %s\n", scenario.When))
	if scenario.Then != nil {
		ctx.WriteString(fmt.Sprintf("Then: %s %s %s\n", scenario.Then.Target, scenario.Then.Op, scenario.Then.Value))
	}
	for _, store := range app.Stores {
		base := shared.StoreBaseName(store.Name)
		ctx.WriteString(fmt.Sprintf("Store: %s -> %sCubit / %sState\n", store.Name, shared.PascalCase(base), shared.PascalCase(base)))
	}

	return Task{
		ID:              fmt.Sprintf("test-%s", pathToID(scenario.ID)),
		Type:            TaskTest,
		TargetFile:      fmt.Sprintf("test/%s_test.dart", pathToID(scenario.ID)),
		ScenarioID:      scenario.ID,
		Description:     fmt.Sprintf("Generate a widget test for scenario %q", scenario.ID),
		PromptContext:   ctx.String(),
		ExpectedOutcome: fmt.Sprintf("Test verifies scenario %q", scenario.ID),
	}
}

func inferStoreAction(app *ir.IR, scenario ir.BehaviorScenario) (string, string) {
	if scenario.When == "" {
		return "", ""
	}
	store, action := data.SplitDot(scenario.When)
	if _, ok := app.Symbols.Stores[store]; ok && action != "" {
		return store, action
	}
	return "", ""
}

func inferStoreField(app *ir.IR, scenario ir.BehaviorScenario) (string, string) {
	if scenario.Then == nil {
		return "", ""
	}
	store, field := data.SplitDot(scenario.Then.Target)
	if _, ok := app.Symbols.Stores[store]; ok && field != "" {
		return store, field
	}
	return "", ""
}

// pathToID turns a scenario path into a slug usable as a file name and a task
// id. Scenario names are prose, so they carry spaces and punctuation; leaving
// those in produced test files like "not decrements when is 0_test.dart",
// which every tool that takes a path had to be careful with, and which the
// Flutter test output parser could not read back.
func pathToID(path string) string {
	var b strings.Builder
	lastUnderscore := true // never start with a separator
	for _, r := range path {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9':
			b.WriteRune(r)
			lastUnderscore = false
		default:
			if !lastUnderscore {
				b.WriteByte('_')
				lastUnderscore = true
			}
		}
	}
	return strings.TrimSuffix(b.String(), "_")
}

func sortedKeys(m map[string]Task) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
