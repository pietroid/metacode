package ir

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
	"github.com/pietroid/metacode/engine/internal/core/spec"
)

func TestResolveCounterApp(t *testing.T) {
	raw := counterAppSpecs()
	app, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}

	if err := app.Resolve(catalog.New()); err != nil {
		t.Fatalf("resolve failed: %v", err)
	}

	if _, ok := app.Symbols.Stores["counterStore"]; !ok {
		t.Error("expected counterStore in symbol table stores")
	}
	if _, ok := app.Symbols.Widgets["homePage"]; !ok {
		t.Error("expected homePage in symbol table widgets")
	}
	if _, ok := app.Symbols.Widgets["counterButton"]; !ok {
		t.Error("expected counterButton in symbol table widgets")
	}
	if _, ok := app.Symbols.Variables["counterValue"]; !ok {
		t.Errorf("expected counterValue variable, got %+v", app.Symbols.Variables)
	}

	if _, ok := app.Symbols.Events["counterButton.onPressed"]; !ok {
		t.Errorf("expected counterButton.onPressed event, got %+v", app.Symbols.Events)
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
	app, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	if err := app.Resolve(catalog.New()); err == nil {
		t.Fatal("expected error for undefined store in assertion")
	}
}

func TestResolveUnknownPropWarning(t *testing.T) {
	raw := spec.RawSpecs{
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{
					"text": map[string]any{
						"unknownProp": "value",
					},
				},
			},
		},
	}
	app, err := Build(raw)
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	app.ValidateUIProps(catalog.New())
	found := false
	for _, w := range app.Warnings {
		if containsString(w, "unknownProp") {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("expected warning for unknownProp, got %+v", app.Warnings)
	}
}

func containsString(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || findSubstr(s, substr))
}

func findSubstr(s, substr string) bool {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
