package behaviorflutter

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

// The fixtures every test in this package shares. Three copies of the counter
// app used to live in three files here, two of them byte-identical.

// counterApp is the example from examples/counter_app: one store, one page, one
// button.
func counterApp() *model.App {
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
					"given": "counterStore.value is 0",
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 1",
				},
				"Show counter value on the home page": map[string]any{
					"given": "counterStore.value = 5",
					"when":  "",
					"then":  "homePage.counterValue = 5",
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

// counterAppTwoButtons adds a second button driving the same store, which is
// the smallest app where a generator can wire the wrong action to the wrong
// widget.
func counterAppTwoButtons(t *testing.T) *model.App {
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
						"body": map[string]any{
							"column": []any{
								map[string]any{"text": "counterValue"},
								"incrementButton",
								"decrementButton",
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
			"not decrements when is 0": map[string]any{
				"given": "counterStore.value is 0",
				"when":  "decrementButton.onPressed",
				"then":  "counterStore.value should be 0",
			},
		},
	}
	app, err := build.App(raw)
	if err != nil {
		t.Fatalf("build ir: %v", err)
	}
	if err := build.Resolve(&app, catalog.Default()); err != nil {
		t.Fatalf("resolve: %v", err)
	}
	return &app
}
