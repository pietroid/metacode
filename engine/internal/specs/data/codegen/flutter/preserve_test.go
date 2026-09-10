package dataflutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/codegen/dart"
	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func counterApp(t *testing.T) *model.App {
	t.Helper()
	raw := spec.RawSpecs{
		Project: map[string]any{"name": "counter_app"},
		Data: map[string]any{
			"stores": map[string]any{
				"counterStore": map[string]any{"value": "int", "initialValue": 0, "strategy": "ephemeral"},
			},
		},
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{
					"scaffold": map[string]any{
						"body": map[string]any{"column": []any{
							map[string]any{"text": "counterValue"},
							"incrementButton",
						}},
					},
				},
				"incrementButton": map[string]any{"elevatedButton": map[string]any{"child": "Increment"}},
			},
		},
		Behaviors: map[string]any{
			"increments from 0": map[string]any{
				"given": map[string]any{"counterStore.value": 0},
				"when":  "incrementButton.onPressed",
				"then":  "counterStore.value should be 1",
			},
		},
	}
	app, err := build.App(raw)
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if err := build.Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	return &app
}

// TestAnImplementedCubitSurvivesTheNextRun is what the whole lock rests on.
// Before this, every run rewrote the Cubit from the template before the
// implement stage ran, so the previous run's bodies were gone by the time
// anything could decide to keep them, and a diff had nothing to protect.
func TestAnImplementedCubitSurvivesTheNextRun(t *testing.T) {
	app := counterApp(t)
	out := t.TempDir()
	if err := Generate(app, out); err != nil {
		t.Fatalf("first run: %v", err)
	}

	path := filepath.Join(out, dart.CubitFile("counterStore"))
	implemented := dart.ImplementedHeader + "\nclass CounterCubit { void increment() { emit(state + 1); } }\n"
	if err := os.WriteFile(path, []byte(implemented), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}

	if err := Generate(app, out); err != nil {
		t.Fatalf("second run: %v", err)
	}

	got, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if string(got) != implemented {
		t.Errorf("the second run overwrote an implemented Cubit:\n%s", got)
	}
}

// TestAStubCubitIsStillRewritten is the other half. A file no model has
// touched carries no work worth keeping, and its signatures have to follow the
// specs.
func TestAStubCubitIsStillRewritten(t *testing.T) {
	app := counterApp(t)
	out := t.TempDir()
	if err := Generate(app, out); err != nil {
		t.Fatalf("first run: %v", err)
	}

	path := filepath.Join(out, dart.CubitFile("counterStore"))
	if !dart.IsStub(path) {
		t.Fatal("a freshly scaffolded Cubit is not marked as a stub")
	}
	if err := os.WriteFile(path, []byte(dart.StubHeader+"\n// emptied\n"), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}

	if err := Generate(app, out); err != nil {
		t.Fatalf("second run: %v", err)
	}
	got, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if !strings.Contains(string(got), "increment") {
		t.Errorf("a stub was not re-scaffolded:\n%s", got)
	}
}

// TestTheStateClassIsAlwaysRewritten: it is derived wholly from the specs and
// no model owns it, so preserving it would only let it go stale.
func TestTheStateClassIsAlwaysRewritten(t *testing.T) {
	app := counterApp(t)
	out := t.TempDir()
	if err := Generate(app, out); err != nil {
		t.Fatalf("first run: %v", err)
	}

	path := filepath.Join(out, dart.StateFile("counterStore"))
	if err := os.WriteFile(path, []byte(dart.ImplementedHeader+"\n// tampered\n"), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}
	if err := Generate(app, out); err != nil {
		t.Fatalf("second run: %v", err)
	}

	got, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if strings.Contains(string(got), "tampered") {
		t.Error("the state class was preserved; only Cubit bodies are a model's to keep")
	}
}
