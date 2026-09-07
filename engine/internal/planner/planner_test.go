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
									"counterButton",
								},
							},
						},
					},
				},
				"counterButton": map[string]any{
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
					"when":  "counterButton.onPressed",
					"then":  "counterStore.value should be 1",
				},
				"increments from 1": map[string]any{
					"given": "counterStore.value is 1",
					"when":  "counterButton.onPressed",
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
	if !wrapperIDs["wrapper-counter_button-on_pressed"] {
		t.Errorf("expected wrapper for counterButton.onPressed, got ids: %v", wrapperIDs)
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

func TestPlanTasksReferenceScenario(t *testing.T) {
	app := counterAppIR()
	tasks, err := Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	for _, task := range tasks {
		if task.ScenarioID == "" {
			t.Errorf("task %q missing scenario id", task.ID)
		}
		if !strings.Contains(task.PromptContext, "Scenario ID:") {
			t.Errorf("task %q missing scenario context", task.ID)
		}
	}
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
