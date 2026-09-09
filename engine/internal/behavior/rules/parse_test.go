package behaviorrules

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
)

func TestParseAssertionShouldBe(t *testing.T) {
	assertion, ok, err := ParseAssertion("counterStore.value should be 6")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !ok {
		t.Fatal("expected assertion to be present")
	}
	if assertion.Target != "counterStore.value" {
		t.Errorf("expected target counterStore.value, got %q", assertion.Target)
	}
	if assertion.Value != "6" {
		t.Errorf("expected value 6, got %q", assertion.Value)
	}
}

func TestParseGivenMapping(t *testing.T) {
	assertion, err := ParseGiven(map[string]any{"counterStore.value": 0})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if assertion.Target != "counterStore.value" {
		t.Errorf("expected target counterStore.value, got %q", assertion.Target)
	}
	if assertion.Value != "0" {
		t.Errorf("expected value 0, got %q", assertion.Value)
	}
}

func TestParseGivenList(t *testing.T) {
	assertion, err := ParseGiven(map[string]any{
		"taskStore.value": []any{map[string]any{"description": "Buy milk", "done": false}},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if assertion.Value != `[{"description":"Buy milk","done":false}]` {
		t.Errorf("unexpected value: %q", assertion.Value)
	}
}

func TestParseGivenRejectsString(t *testing.T) {
	if _, err := ParseGiven("counterStore.value is 0"); err == nil {
		t.Fatal("expected error for a given written as a string")
	}
}

func TestParseGivenRejectsTwoTargets(t *testing.T) {
	_, err := ParseGiven(map[string]any{"a.value": 1, "b.value": 2})
	if err == nil {
		t.Fatal("expected error for a given naming two targets")
	}
}

func TestParseAssertionEmpty(t *testing.T) {
	assertion, ok, err := ParseAssertion("   ")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ok {
		t.Error("expected empty assertion to be absent")
	}
	if assertion != nil {
		t.Error("expected nil assertion for empty string")
	}
}

func TestParseAssertionMalformed(t *testing.T) {
	_, _, err := ParseAssertion("counterStore.value")
	if err == nil {
		t.Fatal("expected error for malformed assertion")
	}
}

func TestParseBehaviorScenario(t *testing.T) {
	scenario, err := ParseBehaviorScenario(
		"counterStore/increments from 0",
		"increments from 0",
		[]string{"counterStore"},
		map[string]any{"counterStore.value": 0},
		"incrementButton.onPressed",
		"counterStore.value should be 1",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if scenario.ID != "counterStore/increments from 0" {
		t.Errorf("unexpected id: %q", scenario.ID)
	}
	if scenario.When != "incrementButton.onPressed" {
		t.Errorf("unexpected when: %q", scenario.When)
	}
	if scenario.Given == nil || scenario.Given.Value != "0" {
		t.Errorf("unexpected given: %+v", scenario.Given)
	}
	if scenario.Then == nil || scenario.Then.Value != "1" {
		t.Errorf("unexpected then: %+v", scenario.Then)
	}
}

func TestParseBehaviorScenarioMissingThen(t *testing.T) {
	_, err := ParseBehaviorScenario("id", "desc", nil, nil, "", "")
	if err == nil {
		t.Fatal("expected error for missing then")
	}
}

func TestParseBehaviorScenarioPureRendering(t *testing.T) {
	scenario, err := ParseBehaviorScenario(
		"render",
		"renders",
		nil,
		nil,
		"",
		"homePage.counterValue should be 5",
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if scenario.Given != nil {
		t.Errorf("expected nil given, got %+v", scenario.Given)
	}
	if scenario.When != "" {
		t.Errorf("expected empty when, got %q", scenario.When)
	}
	if scenario.Then == nil {
		t.Fatal("expected then assertion")
	}
}

// Grouping is the spec's way of writing many concrete cases, so a leaf of any
// nesting must survive as its own scenario. A group that swallowed its cases
// would leave the suite green with most of the spec untested.
func TestBuildScenariosKeepsEveryLeafOfEveryGroupForm(t *testing.T) {
	raw := map[string]any{
		"nested keys": map[string]any{
			"first": map[string]any{
				"given": map[string]any{"store.value": 0},
				"when":  "button.onPressed",
				"then":  "store.value should be 1",
			},
			"second": map[string]any{
				"when": "button.onPressed",
				"then": "store.value should be 2",
			},
		},
		"a list of cases": []any{
			map[string]any{
				"case for 0": map[string]any{
					"given": map[string]any{"store.value": 0},
					"then":  "store.value should be 0",
				},
			},
			map[string]any{
				"case for 1": map[string]any{
					"given": map[string]any{"store.value": 1},
					"then":  "store.value should be 1",
				},
			},
		},
		"deeply": map[string]any{
			"nested": []any{
				map[string]any{
					"leaf": map[string]any{"then": "store.value should be 9"},
				},
			},
		},
	}

	scenarios, err := BuildScenarios(raw)
	if err != nil {
		t.Fatalf("build scenarios: %v", err)
	}

	want := map[string]bool{
		"nested keys/first":          true,
		"nested keys/second":         true,
		"a list of cases/case for 0": true,
		"a list of cases/case for 1": true,
		"deeply/nested/leaf":         true,
	}
	if len(scenarios) != len(want) {
		t.Fatalf("expected %d scenarios, got %d: %+v", len(want), len(scenarios), scenarios)
	}
	for _, s := range scenarios {
		if !want[s.ID] {
			t.Errorf("unexpected scenario id %q", s.ID)
		}
	}
}

func TestParseAssertionUnquotesAValue(t *testing.T) {
	assertion, _, err := ParseAssertion(`taskTile.first.taskTitle should be "Buy milk"`)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if assertion.Value != "Buy milk" {
		t.Errorf("expected value without quotes, got %q", assertion.Value)
	}
}

func TestValidateGivensChecksTheShapeOfASeededElement(t *testing.T) {
	app := &model.App{
		Models: []model.Model{{Name: "task", Fields: []model.Field{
			{Name: "description", Type: "string"},
			{Name: "done", Type: "boolean"},
			{Name: "date", Type: "datetime", Optional: true},
		}}},
		Behaviors: []model.BehaviorScenario{
			{ID: "seeds a typo", Given: &model.Assertion{Target: "taskStore.value", Value: `[{"descriptoin":"Buy milk","done":false}]`}},
		},
		Symbols: model.NewSymbolTable(),
	}
	app.Symbols.Stores["taskStore"] = model.Store{Name: "taskStore", ValueType: "list(task)"}

	errs := ValidateGivens(app)
	if len(errs) != 2 {
		t.Fatalf("expected an unknown field and a missing one, got %v", errs)
	}
}
