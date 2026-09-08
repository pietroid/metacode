package ir

import (
	"fmt"
	"strings"
	"testing"

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
				"increments from 2": map[string]any{
					"given": "counterStore.value is 2",
					"when":  "counterButton.onPressed",
					"then":  "counterStore.value should be 3",
				},
				"Show counter value on the home page": map[string]any{
					"given": "counterStore.value = 5",
					"when":  "",
					"then":  "homePage.counterValue = 5",
				},
			},
		},
	}
}

func TestBuildCounterApp(t *testing.T) {
	raw := counterAppSpecs()
	ir, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	if ir.Project.Name != "counter_app" {
		t.Errorf("expected project name counter_app, got %q", ir.Project.Name)
	}
	if ir.Project.Description != "A simple counter app" {
		t.Errorf("unexpected project description: %q", ir.Project.Description)
	}

	if len(ir.Stores) != 1 {
		t.Fatalf("expected 1 store, got %d", len(ir.Stores))
	}
	store := ir.Stores[0]
	if store.Name != "counterStore" || store.ValueType != "int" || store.Strategy != "ephemeral" {
		t.Errorf("unexpected store: %+v", store)
	}
	if store.InitialValue != 0 {
		t.Errorf("expected initial value 0, got %v", store.InitialValue)
	}

	if len(ir.UI) != 2 {
		t.Fatalf("expected 2 UI components, got %d", len(ir.UI))
	}
	names := map[string]bool{}
	for _, comp := range ir.UI {
		names[comp.Name] = true
	}
	if !names["homePage"] || !names["counterButton"] {
		t.Errorf("expected homePage and counterButton widgets, got: %+v", names)
	}

	if len(ir.Behaviors) != 4 {
		t.Fatalf("expected 4 behavior scenarios, got %d", len(ir.Behaviors))
	}
	for _, s := range ir.Behaviors {
		if s.ID != "counterStore/Show counter value on the home page" && s.When != "counterButton.onPressed" {
			t.Errorf("unexpected when for scenario %q: %q", s.ID, s.When)
		}
	}

	sym, ok := ir.Symbols.Lookup("counterStore")
	if !ok || sym.Kind != "store" {
		t.Errorf("expected counterStore to be registered as store")
	}
	sym, ok = ir.Symbols.Lookup("homePage")
	if !ok || sym.Kind != "widget" {
		t.Errorf("expected homePage to be registered as widget")
	}
}

func TestBuildEmptySpecs(t *testing.T) {
	raw := spec.RawSpecs{
		Project:   map[string]any{},
		Data:      map[string]any{},
		UI:        map[string]any{},
		Behaviors: map[string]any{},
	}
	ir, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	if len(ir.Stores) != 0 || len(ir.UI) != 0 || len(ir.Behaviors) != 0 {
		t.Errorf("expected empty IR from empty specs, got stores=%d ui=%d behaviors=%d", len(ir.Stores), len(ir.UI), len(ir.Behaviors))
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
	ir, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	if ir.Project.Name != "counter_app" {
		t.Errorf("expected project name counter_app, got %q", ir.Project.Name)
	}
	if len(ir.Stores) != 1 || ir.Stores[0].Name != "counterStore" {
		t.Errorf("expected one counterStore, got %+v", ir.Stores)
	}
	if len(ir.UI) != 2 {
		t.Errorf("expected 2 UI components, got %d", len(ir.UI))
	}
	if len(ir.Behaviors) != 4 {
		t.Errorf("expected 4 behavior scenarios, got %d", len(ir.Behaviors))
	}

	homePage := findComponent(ir.UI, "homePage")
	if homePage == nil {
		t.Fatalf("expected homePage component")
	}
	foundVar := false
	for _, v := range homePage.Variables {
		if v == "counterValue" {
			foundVar = true
			break
		}
	}
	if !foundVar {
		t.Errorf("expected counterValue variable in homePage, got %+v", homePage.Variables)
	}
}

func findComponent(components []UIComponent, name string) *UIComponent {
	for i := range components {
		if components[i].Name == name {
			return &components[i]
		}
	}
	return nil
}

func TestBuildIRPrintable(t *testing.T) {
	raw := counterAppSpecs()
	ir, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	// fmt.Sprintf on the full IR should not panic.
	_ = fmt.Sprintf("%+v", ir)
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
	ir, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	foundProject := false
	foundData := false
	for _, w := range ir.Warnings {
		if strings.Contains(w, "author") {
			foundProject = true
		}
		if strings.Contains(w, "unknown") {
			foundData = true
		}
	}
	if !foundProject {
		t.Errorf("expected warning for unknown project key author, got %+v", ir.Warnings)
	}
	if !foundData {
		t.Errorf("expected warning for unknown data key unknown, got %+v", ir.Warnings)
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
	ir, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	if len(ir.UI) != 1 {
		t.Fatalf("expected 1 UI component, got %d", len(ir.UI))
	}
	found := false
	for _, v := range ir.UI[0].Variables {
		if v == "counterValue" {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("expected counterValue to be detected as variable, got %+v", ir.UI[0].Variables)
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

	app, err := Build(raw)
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

	app, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	assertOrder(t, "scenario ids", scenarioIDs(app.Behaviors), []string{"root/branchA/leaf", "root/branchB/leaf"})
}

func storeNames(stores []Store) []string {
	out := make([]string, 0, len(stores))
	for _, s := range stores {
		out = append(out, s.Name)
	}
	return out
}

func componentNames(components []UIComponent) []string {
	out := make([]string, 0, len(components))
	for _, c := range components {
		out = append(out, c.Name)
	}
	return out
}

func scenarioIDs(scenarios []BehaviorScenario) []string {
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
