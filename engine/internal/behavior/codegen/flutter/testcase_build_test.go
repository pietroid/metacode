package behaviorflutter

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/plan"
)

func TestBuildTestCasesProducesWidgetTests(t *testing.T) {
	app := counterApp()
	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	cases, err := BuildTestCases(app, plan)
	if err != nil {
		t.Fatalf("build test cases failed: %v", err)
	}

	if len(cases) != 2 {
		t.Fatalf("expected 2 test cases, got %d", len(cases))
	}

	for _, tc := range cases {
		if tc.PageWrapperClass != "HomePageWrapper" {
			t.Errorf("expected HomePageWrapper, got %q", tc.PageWrapperClass)
		}
	}
}

func TestBuildWidgetTestSeedsAndAssertsText(t *testing.T) {
	app := counterApp()
	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	cases, err := BuildTestCases(app, plan)
	if err != nil {
		t.Fatalf("build test cases failed: %v", err)
	}

	var found bool
	for _, tc := range cases {
		if !strings.Contains(tc.AssertionExpression, "find.text") {
			continue
		}
		found = true
		if tc.SeedState != "CounterState(value: 5)" {
			t.Errorf("expected the seeded state for value 5, got %q", tc.SeedState)
		}
		if tc.AssertionExpression != "expect(find.text('5'), findsOneWidget);" {
			t.Errorf("expected text assertion, got %q", tc.AssertionExpression)
		}
	}
	if !found {
		t.Error("expected a text-asserting widget test")
	}
}

// TestStoreActionScenarioStaysOneWidgetTest covers the 1:1 rule: a scenario
// whose trigger is a store action is still one test against the whole app, not
// a Cubit unit test. Compiling that scenario down to a bloc_test let it pass
// while the widget that was meant to call the action was wired to nothing.
func TestStoreActionScenarioStaysOneWidgetTest(t *testing.T) {
	app := counterApp()
	for i := range app.Behaviors {
		if app.Behaviors[i].ID == "counterStore/increments from 0" {
			app.Behaviors[i].When = "counterStore.increment"
		}
	}

	plan, err := plan.Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	cases, err := BuildTestCases(app, plan)
	if err != nil {
		t.Fatalf("build test cases failed: %v", err)
	}

	var found bool
	for _, tc := range cases {
		if tc.ID != "counterStore/increments from 0" {
			continue
		}
		found = true
		if tc.PageWrapperClass != "HomePageWrapper" {
			t.Errorf("expected the test to pump the page wrapper, got %q", tc.PageWrapperClass)
		}
		if tc.ActionExpression != "cubit.increment();" {
			t.Errorf("expected a direct cubit call, got %q", tc.ActionExpression)
		}
	}
	if !found {
		t.Fatal("no test case for the store-action scenario")
	}
}

func TestDartLiteralForValueSeedsAList(t *testing.T) {
	store := model.Store{Name: "taskStore", ValueType: "list(task)"}
	got, err := dartLiteralForValue(`[{"description":"Buy milk","done":false}]`, store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "[Task(description: 'Buy milk', done: false)]" {
		t.Errorf("unexpected literal: %q", got)
	}
}

func TestDartLiteralForValueRejectsAValueTheStoreCannotHold(t *testing.T) {
	store := model.Store{Name: "counterStore", ValueType: "int"}
	if _, err := dartLiteralForValue("[]", store); err == nil {
		t.Fatal("expected an error for a list seeded into an int store")
	}
}

func TestBuildTestCasesRejectsTwoScenariosWritingOneFile(t *testing.T) {
	app := counterApp()
	work := plan.Work{Tests: []string{
		"counterStore/increments from 0",
		"counterStore/increments from 0",
	}}
	if _, err := BuildTestCases(app, work); err == nil {
		t.Fatal("expected an error when two scenarios target one test file")
	}
}

func TestRowIndexFromTheGiven(t *testing.T) {
	scenario := model.BehaviorScenario{
		Given: &model.Assertion{Target: "taskStore.value", Value: `[{"done":false},{"done":true}]`},
	}
	if got, err := rowIndex(model.RowFirst, scenario); err != nil || got != 0 {
		t.Errorf("first = %d, %v; want 0", got, err)
	}
	if got, err := rowIndex(model.RowLast, scenario); err != nil || got != 1 {
		t.Errorf("last = %d, %v; want 1", got, err)
	}
}

func TestRowIndexNeedsAList(t *testing.T) {
	scenario := model.BehaviorScenario{Given: &model.Assertion{Target: "counterStore.value", Value: "5"}}
	if _, err := rowIndex(model.RowLast, scenario); err == nil {
		t.Fatal("expected an error asking for a list in the given")
	}
}

func TestStoreExpressionReadsAModelField(t *testing.T) {
	app := &model.App{Models: []model.Model{{Name: "task", Fields: []model.Field{{Name: "done", Type: "boolean"}}}}}
	ref := model.ParseRef("taskStore.value.first.done")
	got, err := storeExpression(ref, app, model.Store{Name: "taskStore", ValueType: "list(task)"})
	if err != nil {
		t.Fatal(err)
	}
	if got != "cubit.state.value.first.done" {
		t.Errorf("unexpected expression %q", got)
	}
}

// Without a declared model an element is still a map, so its fields are looked
// up rather than dotted.
func TestStoreExpressionReadsAnUndeclaredElementAsAMap(t *testing.T) {
	ref := model.ParseRef("taskStore.value.first.done")
	got, err := storeExpression(ref, &model.App{}, model.Store{Name: "taskStore", ValueType: "list(task)"})
	if err != nil {
		t.Fatal(err)
	}
	if got != "cubit.state.value.first['done']" {
		t.Errorf("unexpected expression %q", got)
	}
}
