package behaviorrules_test

import (
	"github.com/pietroid/metacode/engine/internal/behavior/rules"
	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func twoButtonSpecs() spec.RawSpecs {
	return spec.RawSpecs{
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
						"body": map[string]any{
							"center": map[string]any{
								"column": []any{"incrementButton", "decrementButton"},
							},
						},
					},
				},
				"incrementButton": map[string]any{"elevatedButton": map[string]any{"child": "Increment"}},
				"decrementButton": map[string]any{"elevatedButton": map[string]any{"child": "Decrement"}},
			},
		},
		Behaviors: map[string]any{
			"increments from 0": map[string]any{
				"given": map[string]any{"counterStore.value": 0},
				"when":  "incrementButton.onPressed",
				"then":  "counterStore.value should be 1",
			},
			"decrements from 2": map[string]any{
				"given": map[string]any{"counterStore.value": 2},
				"when":  "decrementButton.onPressed",
				"then":  "counterStore.value should be 1",
			},
			"not decrements when is 0": map[string]any{
				"given": map[string]any{"counterStore.value": 0},
				"when":  "decrementButton.onPressed",
				"then":  "counterStore.value should be 0",
			},
		},
	}
}

// rowApp is a list whose rows carry a checkbox, so the scenario that toggles
// one names the row it means.
func rowApp(t *testing.T) *model.App {
	t.Helper()
	raw := spec.RawSpecs{
		Project: map[string]any{"name": "task_app"},
		Data: map[string]any{
			"stores": map[string]any{
				"taskStore": map[string]any{"value": "list(text)", "initialValue": []any{}, "strategy": "local"},
			},
		},
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{
					"scaffold": map[string]any{
						"body": map[string]any{"listView": map[string]any{"items": "taskList", "item": "taskTile"}},
					},
				},
				"taskTile":     map[string]any{"listTile": map[string]any{"leading": "taskCheckbox"}},
				"taskCheckbox": map[string]any{"checkbox": map[string]any{"value": "taskDone", "onChanged": "taskToggled"}},
			},
		},
		Behaviors: map[string]any{
			"toggling a row": map[string]any{
				"given": map[string]any{"taskStore.value": []any{"Buy milk"}},
				"when":  "taskCheckbox.first.taskToggled",
				"then":  "taskStore.value.first should be \"Bought milk\"",
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

func resolvedTwoButtonIR(t *testing.T) *model.App {
	t.Helper()
	app, err := build.App(twoButtonSpecs())
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if err := build.Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	return &app
}

// TestResolveBindingsGroupsScenariosByEvent covers the case that used to break
// everything downstream: one action specified by several scenarios. The three
// decrement scenarios describe one method under three preconditions, and the
// floor-at-zero rule is only visible if all three arrive together.
func TestResolveBindingsGroupsScenariosByEvent(t *testing.T) {
	app := resolvedTwoButtonIR(t)

	if len(app.Symbols.Bindings) != 2 {
		t.Fatalf("expected 2 bindings, got %d: %+v", len(app.Symbols.Bindings), app.Symbols.Bindings)
	}

	decrement, ok := app.Symbols.BindingFor("decrementButton", "onPressed")
	if !ok {
		t.Fatal("expected a binding for decrementButton.onPressed")
	}
	if decrement.Store != "counterStore" {
		t.Errorf("store: got %q, want counterStore", decrement.Store)
	}
	if decrement.Action != "decrement" {
		t.Errorf("action: got %q, want decrement", decrement.Action)
	}
	if len(decrement.ScenarioIDs) != 2 {
		t.Errorf("expected both decrement scenarios on one binding, got %v", decrement.ScenarioIDs)
	}

	increment, ok := app.Symbols.BindingFor("incrementButton", "onPressed")
	if !ok {
		t.Fatal("expected a binding for incrementButton.onPressed")
	}
	if increment.Action != "increment" {
		t.Errorf("action: got %q, want increment", increment.Action)
	}
}

// TestActionNameComesFromTheWidgetNotTheNumbers pins the replacement for the
// old rule, which compared the scenario's given and then values as integers and
// answered "increment" when then was larger. That named every button on a
// string store "increment" and could not describe a rule like "clamp at zero",
// where a scenario has then equal to given.
func TestActionNameComesFromTheWidgetNotTheNumbers(t *testing.T) {
	cases := []struct {
		widget string
		event  string
		want   string
	}{
		{"decrementButton", "onPressed", "decrement"},
		{"incrementButton", "onPressed", "increment"},
		{"saveButton", "onPressed", "save"},
		{"nameField", "onChanged", "name"},
		// No kind suffix to strip, so the event supplies the verb.
		{"submit", "onPressed", "submitPressed"},
	}
	for _, tc := range cases {
		got, err := behaviorrules.ActionNameFor(tc.widget, tc.event)
		if err != nil {
			t.Errorf("behaviorrules.ActionNameFor(%q, %q): %v", tc.widget, tc.event, err)
			continue
		}
		if got != tc.want {
			t.Errorf("behaviorrules.ActionNameFor(%q, %q) = %q, want %q", tc.widget, tc.event, got, tc.want)
		}
	}
}

// TestConflictingBindingIsAnError keeps an ambiguous spec from being resolved
// into a silent choice.
func TestConflictingBindingIsAnError(t *testing.T) {
	specs := twoButtonSpecs()
	stores := specs.Data["stores"].(map[string]any)
	stores["otherStore"] = map[string]any{"value": "int", "initialValue": 0, "strategy": "ephemeral"}
	specs.Behaviors["also drives another store"] = map[string]any{
		"given": map[string]any{"otherStore.value": 0},
		"when":  "incrementButton.onPressed",
		"then":  "otherStore.value should be 1",
	}

	app, err := build.App(specs)
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if err := build.Resolve(&app, catalog.Default()); err == nil {
		t.Fatal("expected an error for one event driving two stores")
	}
}

// TestRowSelectorIsNotPartOfTheEvent pins what a binding on a row means: the
// row says which widget fired, not which event it was. The selector used to
// stay in the event name, so the wrapper that wired it wrote
// `first.onChanged:` as a parameter and the file did not compile.
func TestRowSelectorIsNotPartOfTheEvent(t *testing.T) {
	app := rowApp(t)

	if err := behaviorrules.ResolveBindings(app); err != nil {
		t.Fatalf("resolve bindings failed: %v", err)
	}
	if len(app.Symbols.Bindings) != 1 {
		t.Fatalf("expected one binding, got %+v", app.Symbols.Bindings)
	}
	got := app.Symbols.Bindings[0]
	if got.Event != "onChanged" {
		t.Errorf("expected the event without the row selector, got %q", got.Event)
	}
	if got.Widget != "taskCheckbox" {
		t.Errorf("expected the checkbox, got %q", got.Widget)
	}
}
