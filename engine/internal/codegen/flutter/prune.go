package flutter

import (
	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
)

// generatedDirs are the directories this engine owns end to end. Everything in
// them is either produced by a run or left over from an earlier one.
var generatedDirs = []string{"lib/pages", "lib/widgets", "lib/stores", "lib/wrappers", "lib/navigation", "test"}

// PruneStaleOutput deletes generated files whose spec source is gone: a renamed
// widget, a removed scenario, a regrouped behaviors file. It returns the paths
// it removed.
//
// It runs after generation, so a failed run leaves the tree untouched.
func PruneStaleOutput(app *model.App, work plan.Work, outDir string) ([]string, error) {
	expected, err := ExpectedFiles(app, work)
	if err != nil {
		return nil, err
	}
	return dart.Prune(outDir, generatedDirs, expected)
}

// ExpectedFiles is the set of files a run over these specs produces, as paths
// relative to the project root.
//
// Every path here comes from the layout rules the generators themselves use, so
// a renamed file cannot be both written and pruned.
func ExpectedFiles(app *model.App, work plan.Work) (map[string]bool, error) {
	expected := make(map[string]bool)

	for _, comp := range app.UI {
		expected[dart.WidgetFile(comp.Name)] = true
	}
	for _, store := range app.Stores {
		expected[dart.StateFile(store.Name)] = true
		expected[dart.CubitFile(store.Name)] = true
	}
	for _, widget := range work.Wrappers {
		expected[dart.WrapperFile(widget)] = true
	}
	for _, scenarioID := range work.Tests {
		expected[dart.TestFile(scenarioID)] = true
	}

	// The router and the observer the tests verify pushes with exist only
	// while the project declares routes, so removing navigation.yaml removes
	// them like any other spec source that is gone.
	if app.Navigation.Declared() {
		expected[dart.RouterFile()] = true
		expected[dart.NavigationSpyFile()] = true
	}

	return expected, nil
}
