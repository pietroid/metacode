package planner

import (
	"fmt"
	"sort"
	"strings"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/data"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
)

// Plan analyzes the resolved IR and returns an ordered list of generation tasks.
// Wrappers are emitted before tests so later stages can generate runnable code
// before verifying it.
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

	ordered := make([]Task, 0, len(wrappers)+len(tests))
	for _, id := range sortedKeys(wrappers) {
		ordered = append(ordered, wrappers[id])
	}
	ordered = append(ordered, tests...)
	return ordered, nil
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

func pathToID(path string) string {
	return strings.ReplaceAll(path, "/", "_")
}

func sortedKeys(m map[string]Task) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
