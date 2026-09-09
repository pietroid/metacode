package behaviorflutter

import (
	"strings"
	"testing"

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
