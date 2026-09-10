package build

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func TestResolveCounterApp(t *testing.T) {
	raw := counterAppSpecs()
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	if err := Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve failed: %v", err)
	}

	if _, ok := app.Symbols.Stores["counterStore"]; !ok {
		t.Error("expected counterStore in symbol table stores")
	}
	if _, ok := app.Symbols.Widgets["homePage"]; !ok {
		t.Error("expected homePage in symbol table widgets")
	}
	if _, ok := app.Symbols.Widgets["incrementButton"]; !ok {
		t.Error("expected incrementButton in symbol table widgets")
	}
	// Variables are carried on the component that renders them, which is where
	// the widget and project generators read them from.
	page := app.Symbols.Widgets["homePage"]
	if !containsVariable(page.Variables, "counterValue") {
		t.Errorf("expected counterValue among homePage variables, got %+v", page.Variables)
	}

	if _, ok := app.Symbols.Events["incrementButton.onPressed"]; !ok {
		t.Errorf("expected incrementButton.onPressed event, got %+v", app.Symbols.Events)
	}
}

func TestResolveUndefinedStoreInAssertion(t *testing.T) {
	raw := spec.RawSpecs{
		Behaviors: map[string]any{
			"group": map[string]any{
				"scenario": map[string]any{
					"then": "unknownStore.value should be 1",
				},
			},
		},
	}
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	if err := Resolve(&app, catalog.Default()); err == nil {
		t.Fatal("expected error for undefined store in assertion")
	}
}

func TestResolveMarksAWidgetValuedVariable(t *testing.T) {
	raw := spec.RawSpecs{
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{
					"scaffold": map[string]any{"body": "homeContent"},
				},
				"emptyState": map[string]any{
					"center": map[string]any{"text": "Nothing here"},
				},
			},
		},
		Behaviors: map[string]any{
			"renders the empty state": map[string]any{
				"then": "homePage.homeContent should be emptyState",
			},
		},
	}
	app, err := App(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	if err := Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve failed: %v", err)
	}

	sym, ok := app.Symbols.Lookup("homePage.homeContent")
	if !ok || sym.Kind != model.KindWidgetVariable {
		t.Errorf("expected homePage.homeContent to be a widget variable, got %+v", sym)
	}
}

func containsVariable(vars []model.Variable, name string) bool {
	for _, v := range vars {
		if v.Name == name {
			return true
		}
	}
	return false
}
