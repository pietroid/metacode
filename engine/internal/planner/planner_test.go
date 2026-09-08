package planner

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

func counterAppIR() *ir.IR {
	raw := spec.RawSpecs{
		Project: map[string]any{
			"name":        "counter_app",
			"description": "A simple counter app",
		},
		Data: map[string]any{
			"stores": map[string]any{
				"counterStore": map[string]any{
					"value":        "int",
					"initialValue": 0,
					"strategy":     "ephemeral",
				},
			},
		},
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{
					"scaffold": map[string]any{
						"appBar": map[string]any{
							"title": "Counter App",
						},
						"body": map[string]any{
							"center": map[string]any{
								"column": []any{
									map[string]any{"text": "counterValue"},
									"incrementButton",
								},
							},
						},
					},
				},
				"incrementButton": map[string]any{
					"elevatedButton": map[string]any{
						"child": "Increment",
					},
				},
			},
		},
		Behaviors: map[string]any{
			"counterStore": map[string]any{
				"increments from 0": map[string]any{
					"given": "counterStore.value is 0",
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 1",
				},
				"increments from 1": map[string]any{
					"given": "counterStore.value is 1",
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 2",
				},
				"Show counter value on the home page": map[string]any{
					"given": "counterStore.value = 5",
					"when":  "",
					"then":  "homePage.counterValue = 5",
				},
			},
		},
	}
	app, err := ir.Build(raw)
	if err != nil {
		panic(err)
	}
	if err := app.Resolve(catalog.New()); err != nil {
		panic(err)
	}
	return &app
}

func TestPlanCounterAppProducesWrappersAndTests(t *testing.T) {
	app := counterAppIR()
	tasks, err := Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	var wrappers, tests []Task
	for _, task := range tasks {
		switch task.Type {
		case TaskWrapper:
			wrappers = append(wrappers, task)
		case TaskTest:
			tests = append(tests, task)
		}
	}

	if len(wrappers) == 0 {
		t.Fatalf("expected at least one wrapper task, got %d", len(wrappers))
	}
	if len(tests) == 0 {
		t.Fatalf("expected at least one test task, got %d", len(tests))
	}

	wrapperIDs := make(map[string]bool)
	for _, w := range wrappers {
		wrapperIDs[w.ID] = true
	}
	if !wrapperIDs["wrapper-increment_button-on_pressed"] {
		t.Errorf("expected wrapper for incrementButton.onPressed, got ids: %v", wrapperIDs)
	}
	if !wrapperIDs["wrapper-home_page-counter_value"] {
		t.Errorf("expected wrapper for homePage.counterValue, got ids: %v", wrapperIDs)
	}

	for _, task := range wrappers {
		if !strings.HasSuffix(task.TargetFile, "_wrapper.dart") {
			t.Errorf("expected wrapper target file to end with _wrapper.dart, got %q", task.TargetFile)
		}
	}
}

func TestPlanOrdersWrappersBeforeTests(t *testing.T) {
	app := counterAppIR()
	tasks, err := Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	lastWrapper := -1
	firstTest := -1
	for i, task := range tasks {
		if task.Type == TaskWrapper && lastWrapper < i {
			lastWrapper = i
		}
		if task.Type == TaskTest && firstTest == -1 {
			firstTest = i
		}
	}
	if lastWrapper == -1 || firstTest == -1 {
		t.Fatalf("expected both wrapper and test tasks")
	}
	if lastWrapper > firstTest {
		t.Errorf("expected wrappers before tests, last wrapper at %d, first test at %d", lastWrapper, firstTest)
	}
}

// TestPlanTasksAreTraceable checks each task carries what its consumer needs:
// a test task names the scenario it verifies, a wrapper task names the widget
// it wraps. The page wrapper is the one task with no single scenario behind it,
// because every scenario test pumps it.
func TestPlanTasksAreTraceable(t *testing.T) {
	app := counterAppIR()
	tasks, err := Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	for _, task := range tasks {
		switch task.Type {
		case TaskTest:
			if task.ScenarioID == "" {
				t.Errorf("test task %q names no scenario", task.ID)
			}
			if !strings.Contains(task.PromptContext, "Scenario ID:") {
				t.Errorf("test task %q carries no scenario context", task.ID)
			}
		case TaskWrapper:
			if task.Widget == "" {
				t.Errorf("wrapper task %q names no widget", task.ID)
			}
		}
	}
}

// TestPlanAlwaysWrapsThePage covers the case that used to generate tests
// importing a wrapper nothing wrote: no scenario names the page, every test
// pumps it anyway.
func TestPlanAlwaysWrapsThePage(t *testing.T) {
	app := counterAppIR()
	for i := range app.Behaviors {
		if app.Behaviors[i].Then != nil && strings.HasPrefix(app.Behaviors[i].Then.Target, "homePage.") {
			app.Behaviors[i].Then.Target = "counterStore.value"
		}
	}

	tasks, err := Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	for _, task := range tasks {
		if task.Type == TaskWrapper && task.TargetFile == "lib/wrappers/home_page_wrapper.dart" {
			return
		}
	}
	t.Error("no wrapper task for the page")
}

func TestPlanDeduplicatesWrapperTasks(t *testing.T) {
	app := counterAppIR()
	tasks, err := Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	seen := make(map[string]int)
	for _, task := range tasks {
		if task.Type == TaskWrapper {
			seen[task.ID]++
		}
	}
	for id, count := range seen {
		if count > 1 {
			t.Errorf("wrapper task %q duplicated %d times", id, count)
		}
	}
}

func TestPlanNilIR(t *testing.T) {
	_, err := Plan(nil)
	if err == nil {
		t.Fatal("expected error for nil ir")
	}
}

// TestPlanEmitsOneTestPerScenario covers the 1:1 rule: one scenario, one test,
// whatever layers it happens to touch. The planner used to also emit a task per
// store action per scenario so a failing test could be traced back to a file to
// rewrite; the implement stage sees the whole app at once and needs no such map.
func TestPlanEmitsOneTestPerScenario(t *testing.T) {
	app := counterAppIR()
	tasks, err := Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	byScenario := make(map[string]int)
	for _, task := range tasks {
		if task.Type == TaskTest {
			byScenario[task.ScenarioID]++
		}
	}

	if len(byScenario) != len(app.Behaviors) {
		t.Fatalf("expected %d test tasks, got %d", len(app.Behaviors), len(byScenario))
	}
	for _, s := range app.Behaviors {
		if byScenario[s.ID] != 1 {
			t.Errorf("scenario %q has %d test tasks, want exactly 1", s.ID, byScenario[s.ID])
		}
	}
}

// TestPathToIDProducesFileSafeSlugs pins the fix for generated names like
// "not decrements when is 0_test.dart". Spaces in a test path broke the Flutter
// output parser, which broke the mapping from failure to scenario, which
// silently disabled the fix loop.
func TestPathToIDProducesFileSafeSlugs(t *testing.T) {
	cases := map[string]string{
		"counterStore/increments from 0": "counterStore_increments_from_0",
		"not decrements when is 0":       "not_decrements_when_is_0",
		"a//b  c":                        "a_b_c",
	}
	for in, want := range cases {
		if got := pathToID(in); got != want {
			t.Errorf("pathToID(%q) = %q, want %q", in, got, want)
		}
	}
}
