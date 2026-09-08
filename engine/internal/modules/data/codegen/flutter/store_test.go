package flutter

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/ir"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
)

// counterIR builds and resolves the counter app. Resolution is what turns
// "when: incrementButton.onPressed" into a store action, so a store generated
// from an unresolved IR has no methods at all.
func counterIR() *ir.IR {
	app, err := ir.Build(counterAppSpecs())
	if err != nil {
		panic(err)
	}
	if err := app.Resolve(catalog.New()); err != nil {
		panic(err)
	}
	return &app
}

func TestGenerateStoresCounterApp(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, dir); err != nil {
		t.Fatalf("generate stores failed: %v", err)
	}

	for _, name := range []string{"lib/stores/counter_state.dart", "lib/stores/counter_cubit.dart"} {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			t.Errorf("expected %s to exist: %v", name, err)
		}
	}
}

func TestCounterStateContents(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, dir); err != nil {
		t.Fatalf("generate stores failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "stores", "counter_state.dart"))
	if err != nil {
		t.Fatalf("read state: %v", err)
	}
	content := string(data)
	if !strings.Contains(content, "class CounterState extends Equatable") {
		t.Errorf("expected CounterState class, got:\n%s", content)
	}
	if !strings.Contains(content, "final int value") {
		t.Errorf("expected final int value, got:\n%s", content)
	}
}

func TestCounterCubitContents(t *testing.T) {
	dir := t.TempDir()
	app := counterIR()
	if err := Generate(app, dir); err != nil {
		t.Fatalf("generate stores failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "stores", "counter_cubit.dart"))
	if err != nil {
		t.Fatalf("read cubit: %v", err)
	}
	content := string(data)
	if !strings.Contains(content, "class CounterCubit extends Cubit<CounterState>") {
		t.Errorf("expected CounterCubit class, got:\n%s", content)
	}
	if !strings.Contains(content, "void increment()") {
		t.Errorf("expected increment method, got:\n%s", content)
	}
	if !strings.Contains(content, "UnimplementedError") {
		t.Errorf("expected the body to be left to the fix loop, got:\n%s", content)
	}
	if !strings.Contains(content, "/// Specified by:") {
		t.Errorf("expected the scenarios that specify the action, got:\n%s", content)
	}
	if !strings.Contains(content, "CounterCubit() : super(const CounterState(value: 0))") {
		t.Errorf("expected constructor with initial value, got:\n%s", content)
	}
}

// TestGenerateStoresWithoutActions pins the rule that a store's API comes from
// the specs and nowhere else. The generator used to add "increment" to every
// numeric store, which put a method on the Cubit that no scenario asked for.
func TestGenerateStoresWithoutActions(t *testing.T) {
	dir := t.TempDir()
	app, err := ir.Build(counterAppSpecs())
	if err != nil {
		t.Fatalf("build failed: %v", err)
	}
	app.Behaviors = nil
	if err := app.Resolve(catalog.New()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if err := Generate(&app, dir); err != nil {
		t.Fatalf("generate stores failed: %v", err)
	}
	data, err := os.ReadFile(filepath.Join(dir, "lib", "stores", "counter_cubit.dart"))
	if err != nil {
		t.Fatalf("read cubit: %v", err)
	}
	if strings.Contains(string(data), "void increment()") {
		t.Errorf("expected no action for a store no scenario drives, got:\n%s", data)
	}
}

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
					"given": "counterStore.value is 0",
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 1",
				},
			},
		},
	}
}
