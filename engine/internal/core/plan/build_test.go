package plan

import (
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func counterAppIR() *model.App {
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
					"given": map[string]any{"counterStore.value": 0},
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 1",
				},
				"increments from 1": map[string]any{
					"given": map[string]any{"counterStore.value": 1},
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 2",
				},
				"Show counter value on the home page": map[string]any{
					"given": map[string]any{"counterStore.value": 5},
					"when":  "",
					"then":  "homePage.counterValue should be 5",
				},
			},
		},
	}
	app, err := build.App(raw)
	if err != nil {
		panic(err)
	}
	if err := build.Resolve(&app, catalog.Default()); err != nil {
		panic(err)
	}
	return &app
}

func TestPlanCounterAppProducesWrappersAndTests(t *testing.T) {
	app := counterAppIR()
	work, err := Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	if len(work.Wrappers) == 0 {
		t.Fatal("expected at least one wrapper")
	}
	if len(work.Tests) == 0 {
		t.Fatal("expected at least one test")
	}

	widgets := make(map[string]bool)
	for _, w := range work.Wrappers {
		widgets[w] = true
	}
	// The page, and every widget with something to wire. A button whose event a
	// behavior binds is reached through its own wrapper, and the page takes it
	// as a slot.
	for _, want := range []string{"homePage", "incrementButton"} {
		if !widgets[want] {
			t.Errorf("expected a wrapper for %s, got %v", want, work.Wrappers)
		}
	}
}

// TestPlanIsOrdered pins the two ordering guarantees every generator relies on:
// wrappers in a stable order whatever the map iteration does, and tests in the
// order the specs declare them.
func TestPlanIsOrdered(t *testing.T) {
	app := counterAppIR()

	first, err := Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	for i := 0; i < 10; i++ {
		again, err := Build(app)
		if err != nil {
			t.Fatalf("plan failed: %v", err)
		}
		if strings.Join(again.Wrappers, ",") != strings.Join(first.Wrappers, ",") {
			t.Fatalf("wrapper order is not stable: %v then %v", first.Wrappers, again.Wrappers)
		}
	}

	if len(first.Tests) != len(app.Behaviors) {
		t.Fatalf("expected one test per scenario, got %d tests for %d scenarios", len(first.Tests), len(app.Behaviors))
	}
	for i, test := range first.Tests {
		if test != app.Behaviors[i].ID {
			t.Errorf("test %d verifies %q, expected %q", i, test, app.Behaviors[i].ID)
		}
	}
}

// TestPlanNamesWhatItPlans checks each entry carries what its consumer needs:
// a test names the scenario it verifies, a wrapper names the widget it wraps.
func TestPlanNamesWhatItPlans(t *testing.T) {
	app := counterAppIR()
	work, err := Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	for _, test := range work.Tests {
		if test == "" {
			t.Error("a planned test names no scenario")
		}
	}
	for _, wrapper := range work.Wrappers {
		if wrapper == "" {
			t.Error("a planned wrapper names no widget")
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

	work, err := Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}
	for _, wrapper := range work.Wrappers {
		if wrapper == "homePage" {
			return
		}
	}
	t.Errorf("no wrapper for the page, got %v", work.Wrappers)
}

// TestPlanWrapsEachWidgetOnce covers the widget named by several scenarios:
// one wrapper file, not one per mention.
func TestPlanWrapsEachWidgetOnce(t *testing.T) {
	app := counterAppIR()
	work, err := Build(app)
	if err != nil {
		t.Fatalf("plan failed: %v", err)
	}

	seen := make(map[string]int)
	for _, wrapper := range work.Wrappers {
		seen[wrapper]++
	}
	for widget, count := range seen {
		if count > 1 {
			t.Errorf("widget %q planned %d times", widget, count)
		}
	}
}
