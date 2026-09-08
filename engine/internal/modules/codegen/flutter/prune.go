package flutter

import (
	"fmt"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/modules/codegen"
	"github.com/pietroid/metacode/engine/internal/modules/shared"
	"github.com/pietroid/metacode/engine/internal/modules/tests"
	wrappersflutter "github.com/pietroid/metacode/engine/internal/modules/wrappers/codegen/flutter"
	"github.com/pietroid/metacode/engine/internal/planner"
)

// generatedDirs are the directories this engine owns end to end. Everything in
// them is either produced by a run or left over from an earlier one.
var generatedDirs = []string{"lib/pages", "lib/widgets", "lib/stores", "lib/wrappers", "test"}

// PruneStaleOutput deletes generated files whose spec source is gone: a renamed
// widget, a removed scenario, a regrouped behaviors file. It returns the paths
// it removed.
//
// It runs after generation, so a failed run leaves the tree untouched.
func PruneStaleOutput(app *ir.IR, tasks []planner.Task, outDir string) ([]string, error) {
	expected, err := ExpectedFiles(app, tasks)
	if err != nil {
		return nil, err
	}
	return codegen.Prune(outDir, generatedDirs, expected)
}

// ExpectedFiles is the set of files a run over these specs produces, as paths
// relative to the project root.
//
// Wrapper and test paths come from the same planning the generators use, so
// they cannot drift. Page, widget and store paths restate the naming rule,
// which is the one place this has to be kept in step with its generator.
func ExpectedFiles(app *ir.IR, tasks []planner.Task) (map[string]bool, error) {
	expected := make(map[string]bool)

	for _, comp := range app.UI {
		dir := "lib/widgets"
		if shared.IsPageName(comp.Name) {
			dir = "lib/pages"
		}
		expected[fmt.Sprintf("%s/%s.dart", dir, shared.SnakeCase(comp.Name))] = true
	}

	for _, store := range app.Stores {
		base := shared.SnakeCase(shared.StoreBaseName(store.Name))
		expected[fmt.Sprintf("lib/stores/%s_state.dart", base)] = true
		expected[fmt.Sprintf("lib/stores/%s_cubit.dart", base)] = true
	}

	for _, plan := range wrappersflutter.PlanWrappers(app, tasks) {
		expected[plan.TargetFile] = true
	}

	cases, err := tests.BuildTestCases(app, tasks)
	if err != nil {
		return nil, fmt.Errorf("build test cases: %w", err)
	}
	for _, tc := range cases {
		expected[tc.TargetFile] = true
	}

	return expected, nil
}
