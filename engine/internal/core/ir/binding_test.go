package ir

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/modules/ui/catalog"
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
				"given": "counterStore.value is 0",
				"when":  "incrementButton.onPressed",
				"then":  "counterStore.value should be 1",
			},
			"decrements from 2": map[string]any{
				"given": "counterStore.value is 2",
				"when":  "decrementButton.onPressed",
				"then":  "counterStore.value should be 1",
			},
			"not decrements when is 0": map[string]any{
				"given": "counterStore.value is 0",
				"when":  "decrementButton.onPressed",
				"then":  "counterStore.value should be 0",
			},
		},
	}
}

func resolvedTwoButtonIR(t *testing.T) *IR {
	t.Helper()
	app, err := Build(twoButtonSpecs())
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if err := app.Resolve(catalog.New()); err != nil {
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
		got, err := ActionNameFor(tc.widget, tc.event)
		if err != nil {
			t.Errorf("ActionNameFor(%q, %q): %v", tc.widget, tc.event, err)
			continue
		}
		if got != tc.want {
			t.Errorf("ActionNameFor(%q, %q) = %q, want %q", tc.widget, tc.event, got, tc.want)
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
		"given": "otherStore.value is 0",
		"when":  "incrementButton.onPressed",
		"then":  "otherStore.value should be 1",
	}

	app, err := Build(specs)
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if err := app.Resolve(catalog.New()); err == nil {
		t.Fatal("expected an error for one event driving two stores")
	}
}
