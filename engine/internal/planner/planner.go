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

	stores := buildStoreTasks(app)

	ordered := make([]Task, 0, len(stores)+len(wrappers)+len(tests))
	ordered = append(ordered, stores...)
	for _, id := range sortedKeys(wrappers) {
		ordered = append(ordered, wrappers[id])
	}
	ordered = append(ordered, tests...)
	return ordered, nil
}

// buildStoreTasks emits one task per store action, so a failing test can be
// traced back to the Cubit method that has to change. Without these the fix
// loop can only edit wrappers, which is what drove generated wrappers to reach
// through cubit.emit for logic that belonged in the store.
func buildStoreTasks(app *ir.IR) []Task {
	var tasks []Task
	for _, binding := range app.Symbols.Bindings {
		base := shared.StoreBaseName(binding.Store)
		targetFile := fmt.Sprintf("lib/stores/%s_cubit.dart", shared.SnakeCase(base))

		ctx := strings.Builder{}
		ctx.WriteString(fmt.Sprintf("Scenario ID: %s\n", binding.ScenarioIDs[0]))
		ctx.WriteString(fmt.Sprintf("Store: %s\n", binding.Store))
		ctx.WriteString(fmt.Sprintf("Action: %s\n", binding.Action))
		ctx.WriteString(fmt.Sprintf("Triggered by: %s\n", binding.FullPath()))
		ctx.WriteString("Scenarios this action must satisfy:\n")
		for _, id := range binding.ScenarioIDs {
			scenario, ok := findScenario(app, id)
			if !ok {
				continue
			}
			ctx.WriteString(fmt.Sprintf("  - %s\n", scenario.ID))
			if scenario.Given != nil {
				ctx.WriteString(fmt.Sprintf("      Given: %s %s %s\n", scenario.Given.Target, scenario.Given.Op, scenario.Given.Value))
			}
			if scenario.Then != nil {
				ctx.WriteString(fmt.Sprintf("      Then: %s %s %s\n", scenario.Then.Target, scenario.Then.Op, scenario.Then.Value))
			}
		}

		// One task per scenario, all targeting the same Cubit file. A failing
		// test is traced back through its scenario, so an action specified by
		// three scenarios has to be reachable from any of the three.
		for _, id := range binding.ScenarioIDs {
			tasks = append(tasks, Task{
				ID:              fmt.Sprintf("store-%s-%s-%s", shared.SnakeCase(base), shared.SnakeCase(binding.Action), pathToID(id)),
				Type:            TaskStore,
				TargetFile:      targetFile,
				ScenarioID:      id,
				Description:     fmt.Sprintf("Implement %s.%s", binding.Store, binding.Action),
				PromptContext:   ctx.String(),
				ExpectedOutcome: fmt.Sprintf("%s.%s satisfies every scenario that triggers it", binding.Store, binding.Action),
			})
		}
	}
	return tasks
}

func findScenario(app *ir.IR, id string) (ir.BehaviorScenario, bool) {
	for _, s := range app.Behaviors {
		if s.ID == id {
			return s, true
		}
	}
	return ir.BehaviorScenario{}, false
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
