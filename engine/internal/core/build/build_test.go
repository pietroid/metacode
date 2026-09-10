package build

import (
	"fmt"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
)

func counterAppSpecs() spec.RawSpecs {
	return spec.RawSpecs{
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
							"title": "Counter model.App",
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
				"increments from 2": map[string]any{
					"given": map[string]any{"counterStore.value": 2},
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 3",
				},
				"Show counter value on the home page": map[string]any{
					"given": map[string]any{"counterStore.value": 5},
					"when":  "",
					"then":  "homePage.counterValue should be 5",
				},
			},
		},
	}
}

// TestBuildCounterApp checks each section of the model the counter app's specs
// describe. One subtest per section, so a failure names the section rather than
// a line in one long function.
func TestBuildCounterApp(t *testing.T) {
	app, err := App(counterAppSpecs())
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	t.Run("project", func(t *testing.T) {
		if app.Project.Name != "counter_app" {
			t.Errorf("expected project name counter_app, got %q", app.Project.Name)
		}
		if app.Project.Description != "A simple counter app" {
			t.Errorf("unexpected project description: %q", app.Project.Description)
		}
	})

	t.Run("stores", func(t *testing.T) {
		if len(app.Stores) != 1 {
			t.Fatalf("expected 1 store, got %d", len(app.Stores))
		}
		store := app.Stores[0]
		if store.Name != "counterStore" || store.ValueType != "int" || store.Strategy != "ephemeral" {
			t.Errorf("unexpected store: %+v", store)
		}
		if store.InitialValue != 0 {
			t.Errorf("expected initial value 0, got %v", store.InitialValue)
		}
	})

	t.Run("widgets", func(t *testing.T) {
		names := map[string]bool{}
		for _, comp := range app.UI {
			names[comp.Name] = true
		}
		if len(app.UI) != 2 || !names["homePage"] || !names["incrementButton"] {
			t.Errorf("expected homePage and incrementButton widgets, got %+v", names)
		}
	})

	t.Run("scenarios", func(t *testing.T) {
		if len(app.Behaviors) != 4 {
			t.Fatalf("expected 4 behavior scenarios, got %d", len(app.Behaviors))
		}
		for _, scenario := range app.Behaviors {
			if scenario.ID == "counterStore/Show counter value on the home page" {
				continue // the one scenario with no trigger
			}
			if scenario.When != "incrementButton.onPressed" {
				t.Errorf("unexpected when for scenario %q: %q", scenario.ID, scenario.When)
			}
		}
	})

	t.Run("symbols", func(t *testing.T) {
		for name, kind := range map[string]string{"counterStore": "store", "homePage": "widget"} {
			sym, ok := app.Symbols.Lookup(name)
			if !ok {
				t.Errorf("%s is not registered", name)
				continue
			}
			if sym.Kind != kind {
				t.Errorf("expected %s to be a %s, got %s", name, kind, sym.Kind)
			}
		}
	})
}

func TestBuildEmptySpecs(t *testing.T) {
	raw := spec.RawSpecs{
		Project:   map[string]any{},
		Data:      map[string]any{},
		UI:        map[string]any{},
		Behaviors: map[string]any{},
	}
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	if len(app.Stores) != 0 || len(app.UI) != 0 || len(app.Behaviors) != 0 {
		t.Errorf("expected empty model.App from empty specs, got stores=%d ui=%d behaviors=%d", len(app.Stores), len(app.UI), len(app.Behaviors))
	}
}

func TestBuildFromCounterAppYAML(t *testing.T) {
	paths, err := spec.Discover("../../../../examples/counter_app")
	if err != nil {
		t.Fatalf("discover: %v", err)
	}
	raw, err := spec.Parse(paths)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	if app.Project.Name != "counter_app" {
		t.Errorf("expected project name counter_app, got %q", app.Project.Name)
	}
	if len(app.Stores) != 1 || app.Stores[0].Name != "counterStore" {
		t.Errorf("expected one counterStore, got %+v", app.Stores)
	}
	// This test reads examples/counter_app, which grows as the example does, so
	// it checks that the pieces it needs are present rather than counting them.
	if len(app.UI) < 2 {
		t.Errorf("expected at least 2 UI components, got %d", len(app.UI))
	}
	if len(app.Behaviors) < 4 {
		t.Errorf("expected at least 4 behavior scenarios, got %d", len(app.Behaviors))
	}

	homePage := findComponent(app.UI, "homePage")
	if homePage == nil {
		t.Fatalf("expected homePage component")
	}
	foundVar := false
	for _, v := range homePage.Variables {
		if v.Name == "counterValue" {
			foundVar = true
			break
		}
	}
	if !foundVar {
		t.Errorf("expected counterValue variable in homePage, got %+v", homePage.Variables)
	}
}

func findComponent(components []model.UIComponent, name string) *model.UIComponent {
	for i := range components {
		if components[i].Name == name {
			return &components[i]
		}
	}
	return nil
}

func TestBuildAppPrintable(t *testing.T) {
	raw := counterAppSpecs()
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	// fmt.Sprintf on the full model.App should not panic.
	_ = fmt.Sprintf("%+v", app)
}

func TestBuildWarnsUnknownTopLevelKeys(t *testing.T) {
	raw := spec.RawSpecs{
		Project: map[string]any{
			"name":   "app",
			"author": "metacode",
		},
		Data: map[string]any{
			"stores":  map[string]any{},
			"unknown": "value",
		},
		UI: map[string]any{
			"widgets": map[string]any{},
		},
		Behaviors: map[string]any{},
	}
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	foundProject := false
	foundData := false
	for _, w := range app.Warnings {
		if strings.Contains(w, "author") {
			foundProject = true
		}
		if strings.Contains(w, "unknown") {
			foundData = true
		}
	}
	if !foundProject {
		t.Errorf("expected warning for unknown project key author, got %+v", app.Warnings)
	}
	if !foundData {
		t.Errorf("expected warning for unknown data key unknown, got %+v", app.Warnings)
	}
}

func TestBuildDetectsVariables(t *testing.T) {
	raw := spec.RawSpecs{
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{
					"text": "counterValue",
				},
			},
		},
	}
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	if len(app.UI) != 1 {
		t.Fatalf("expected 1 UI component, got %d", len(app.UI))
	}
	found := false
	for _, v := range app.UI[0].Variables {
		if v.Name == "counterValue" {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("expected counterValue to be detected as variable, got %+v", app.UI[0].Variables)
	}
}

// TestBuildOrdersDeclarationsLexicographically pins the ordering guarantee that
// reproducible generation depends on. Go randomizes map iteration, so without
// sorting these slices arrive in a different order on every run and the
// generated files differ from identical specs.
func TestBuildOrdersDeclarationsLexicographically(t *testing.T) {
	raw := spec.RawSpecs{
		Data: map[string]any{
			"stores": map[string]any{
				"zebraStore": map[string]any{"value": "int"},
				"alphaStore": map[string]any{"value": "int"},
				"midStore":   map[string]any{"value": "int"},
			},
		},
		UI: map[string]any{
			"widgets": map[string]any{
				"zebraWidget": map[string]any{"text": "z"},
				"alphaWidget": map[string]any{"text": "a"},
				"midWidget":   map[string]any{"text": "m"},
			},
		},
		Behaviors: map[string]any{
			"zebraGroup": map[string]any{
				"scenario": map[string]any{"then": "alphaStore.value should be 1"},
			},
			"alphaGroup": map[string]any{
				"scenario": map[string]any{"then": "alphaStore.value should be 1"},
			},
		},
	}

	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	assertOrder(t, "stores", storeNames(app.Stores), []string{"alphaStore", "midStore", "zebraStore"})
	assertOrder(t, "widgets", componentNames(app.UI), []string{"alphaWidget", "midWidget", "zebraWidget"})
	assertOrder(t, "behaviors", scenarioIDs(app.Behaviors), []string{"alphaGroup/scenario", "zebraGroup/scenario"})
}

// TestBuildKeepsGroupPathsIndependent covers the aliasing defect where sibling
// groups appended into a shared backing array and overwrote each other's path.
// It needs three levels of nesting to reproduce.
func TestBuildKeepsGroupPathsIndependent(t *testing.T) {
	raw := spec.RawSpecs{
		Behaviors: map[string]any{
			"root": map[string]any{
				"branchA": map[string]any{
					"leaf": map[string]any{"then": "s.value should be 1"},
				},
				"branchB": map[string]any{
					"leaf": map[string]any{"then": "s.value should be 2"},
				},
			},
		},
	}

	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	assertOrder(t, "scenario ids", scenarioIDs(app.Behaviors), []string{"root/branchA/leaf", "root/branchB/leaf"})
}

func storeNames(stores []model.Store) []string {
	out := make([]string, 0, len(stores))
	for _, s := range stores {
		out = append(out, s.Name)
	}
	return out
}

func componentNames(components []model.UIComponent) []string {
	out := make([]string, 0, len(components))
	for _, c := range components {
		out = append(out, c.Name)
	}
	return out
}

func scenarioIDs(scenarios []model.BehaviorScenario) []string {
	out := make([]string, 0, len(scenarios))
	for _, s := range scenarios {
		out = append(out, s.ID)
	}
	return out
}

func assertOrder(t *testing.T, label string, got, want []string) {
	t.Helper()
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Errorf("%s: expected %v, got %v", label, want, got)
	}
}
