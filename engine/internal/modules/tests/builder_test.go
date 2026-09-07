package tests

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/planner"
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

func TestBuildTestCasesProducesWidgetTests(t *testing.T) {
	app := counterAppIR()
	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	cases, err := BuildTestCases(app, tasks)
	if err != nil {
		t.Fatalf("build test cases failed: %v", err)
	}

	if len(cases) != 2 {
		t.Fatalf("expected 2 test cases, got %d", len(cases))
	}

	for _, tc := range cases {
		if tc.Type != TestTypeWidget {
			t.Errorf("expected widget test, got %q", tc.Type)
		}
		if tc.PageWrapperClass != "HomePageWrapper" {
			t.Errorf("expected HomePageWrapper, got %q", tc.PageWrapperClass)
		}
	}
}

func TestBuildWidgetTestSeedsAndAssertsText(t *testing.T) {
	app := counterAppIR()
	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	cases, err := BuildTestCases(app, tasks)
	if err != nil {
		t.Fatalf("build test cases failed: %v", err)
	}

	var found bool
	for _, tc := range cases {
		if tc.Type != TestTypeWidget || !strings.Contains(tc.AssertionExpression, "find.text") {
			continue
		}
		found = true
		if tc.SeedExpression != "cubit.emit(CounterState(value: 5));" {
			t.Errorf("expected seed expression for value 5, got %q", tc.SeedExpression)
		}
		if tc.AssertionExpression != "expect(find.text('5'), findsOneWidget);" {
			t.Errorf("expected text assertion, got %q", tc.AssertionExpression)
		}
	}
	if !found {
		t.Error("expected a text-asserting widget test")
	}
}

func TestBuildCubitTestAssertsState(t *testing.T) {
	app := counterAppIR()
	// Replace the widget event with a direct store action scenario.
	for i := range app.Behaviors {
		if app.Behaviors[i].ID == "counterStore/increments from 0" {
			app.Behaviors[i].When = "counterStore.increment"
		}
	}

	tasks, err := planner.Plan(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	cases, err := BuildTestCases(app, tasks)
	if err != nil {
		t.Fatalf("build test cases failed: %v", err)
	}

	for _, tc := range cases {
		if tc.Type != TestTypeCubit {
			continue
		}
		if tc.ActionExpression != "act: (cubit) => cubit.increment()," {
			t.Errorf("expected increment action, got %q", tc.ActionExpression)
		}
		if tc.AssertionExpression != "expect: () => [CounterState(value: 1)]," {
			t.Errorf("expected state assertion, got %q", tc.AssertionExpression)
		}
	}
}
