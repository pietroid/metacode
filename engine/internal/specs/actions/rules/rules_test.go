package actionrules

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/actions/catalog"
)

func appWithRoutes() *model.App {
	app := &model.App{
		Symbols: model.NewSymbolTable(),
		Navigation: model.Navigation{
			InitialRoute: "home",
			Routes: []model.Route{
				{Name: "home", Child: "homePage", Type: model.RoutePage},
				{Name: "addTask", Child: "addTaskSheet", Type: model.RouteBottomSheet},
			},
		},
	}
	return app
}

func TestCheckAssertionAcceptsTheNatives(t *testing.T) {
	c := actioncatalog.Default()
	app := appWithRoutes()

	for _, a := range []model.Assertion{
		{Target: "navigator", Verb: "push", Value: "addTask"},
		{Target: "navigator", Verb: "pop"},
	} {
		if err := CheckAssertion(app, &a, c); err != nil {
			t.Errorf("%s: unexpected error: %v", a.Sentence(), err)
		}
	}
}

// The route vocabulary is closed, the same way the icon one is, so a name that
// is not in it is a typo the author can fix rather than a compile error in a
// file nobody wrote.
func TestCheckAssertionRejects(t *testing.T) {
	c := actioncatalog.Default()
	app := appWithRoutes()

	cases := map[string]struct {
		assertion model.Assertion
		wants     string
	}{
		"unknown verb":    {model.Assertion{Target: "navigator", Verb: "shove", Value: "addTask"}, "pop, push"},
		"unknown route":   {model.Assertion{Target: "navigator", Verb: "push", Value: "nowhere"}, "declares no route"},
		"push needs one":  {model.Assertion{Target: "navigator", Verb: "push"}, "needs a route"},
		"pop takes none":  {model.Assertion{Target: "navigator", Verb: "pop", Value: "addTask"}, "one word too many"},
		"unknown subject": {model.Assertion{Target: "speaker", Verb: "play", Value: "chime"}, "not an action subject"},
	}
	for name, tc := range cases {
		err := CheckAssertion(app, &tc.assertion, c)
		if err == nil {
			t.Errorf("%s: expected an error", name)
			continue
		}
		if !strings.Contains(err.Error(), tc.wants) {
			t.Errorf("%s: expected an error mentioning %q, got %v", name, tc.wants, err)
		}
	}
}

// An action with no `when` compiles to a test that pumps the app and checks a
// call nobody made.
func TestAnActionNeedsSomethingToFireIt(t *testing.T) {
	c := actioncatalog.Default()
	app := appWithRoutes()

	scenario := model.BehaviorScenario{
		ID:   "opens the sheet",
		Then: &model.Assertion{Target: "navigator", Verb: "push", Value: "addTask"},
	}
	if err := CheckScenario(app, scenario, c); err == nil {
		t.Fatal("expected an error for an action with no when")
	}

	scenario.When = "counterStore.increment"
	if err := CheckScenario(app, scenario, c); err == nil {
		t.Fatal("expected an error for an action fired by something that is not a widget event")
	}

	app.Symbols.Events["addTaskButton.onAddTask"] = model.EventRef{Widget: "addTaskButton", Address: "onAddTask", Event: "onPressed"}
	scenario.When = "addTaskButton.onAddTask"
	if err := CheckScenario(app, scenario, c); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCheckScenarioChecksTheGivenRoute(t *testing.T) {
	c := actioncatalog.Default()
	app := appWithRoutes()

	scenario := model.BehaviorScenario{ID: "s", GivenRoute: "nowhere", Then: &model.Assertion{Target: "counterStore.value", Verb: model.VerbBe, Value: "1"}}
	if err := CheckScenario(app, scenario, c); err == nil {
		t.Error("expected an error for a route that is not declared")
	}

	// Starting where the app already opens says nothing.
	scenario.GivenRoute = "home"
	if err := CheckScenario(app, scenario, c); err == nil {
		t.Error("expected an error for a given naming the initial route")
	}

	scenario.GivenRoute = "addTask"
	if err := CheckScenario(app, scenario, c); err != nil {
		t.Errorf("unexpected error: %v", err)
	}
}

// Two scenarios about one press are one binding, and a press that both writes
// the store and moves the app appears in both lists.
func TestResolveActionBindingsSharesOneBindingPerEvent(t *testing.T) {
	c := actioncatalog.Default()
	app := appWithRoutes()
	app.Symbols.Events["saveButton.onSave"] = model.EventRef{Widget: "saveButton", Address: "onSave", Event: "onPressed"}
	app.Behaviors = []model.BehaviorScenario{
		{ID: "a", When: "saveButton.onSave", Then: &model.Assertion{Target: "navigator", Verb: "pop"}},
		{ID: "b", When: "saveButton.onSave", Then: &model.Assertion{Target: "navigator", Verb: "pop"}},
		{ID: "c", When: "saveButton.onSave", Then: &model.Assertion{Target: "counterStore.value", Verb: model.VerbBe, Value: "1"}},
	}

	if err := ResolveActionBindings(app, c); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(app.Symbols.ActionBindings) != 1 {
		t.Fatalf("expected one binding, got %v", app.Symbols.ActionBindings)
	}
	binding := app.Symbols.ActionBindings[0]
	if binding.Call() != "navigator.pop" {
		t.Errorf("unexpected call %q", binding.Call())
	}
	if len(binding.ScenarioIDs) != 2 {
		t.Errorf("expected both scenarios on the binding, got %v", binding.ScenarioIDs)
	}
}
