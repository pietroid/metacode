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
					"given": map[string]any{"counterStore.value": 0},
					"when":  "incrementButton.onPressed",
					"then":  "counterStore.value should be 1",
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
				"given": map[string]any{"counterStore.value": 0},
				"when":  "incrementButton.onPressed",
				"then":  "counterStore.value should be 1",
			},
			"not decrements when is 0": map[string]any{
				"given": map[string]any{"counterStore.value": 0},
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

// listApp is a screen whose content is a list: a page, a state widget holding
// the listView, the row it builds one of per element, and a checkbox inside
// that row. It is the shape that says whether wrappers nest, because every
// level of it has something of its own to wire.
func listApp(t *testing.T) *model.App {
	t.Helper()
	raw := spec.RawSpecs{
		Project: map[string]any{"name": "task_app", "description": "A task list"},
		Data: map[string]any{
			"stores": map[string]any{
				"taskStore": map[string]any{"value": "list(text)", "initialValue": []any{}, "strategy": "local"},
			},
		},
		UI: map[string]any{
			"widgets": map[string]any{
				"homePage": map[string]any{"scaffold": map[string]any{"body": "homeContent"}},
				"defaultState": map[string]any{
					"column": []any{
						map[string]any{"listView": map[string]any{"items": "taskList", "item": "taskTile"}},
					},
				},
				"taskTile": map[string]any{
					"listTile": map[string]any{"title": "taskTitle", "leading": "taskCheckbox"},
				},
				"taskCheckbox": map[string]any{
					"checkbox": map[string]any{"value": "taskDone", "onChanged": "taskToggled"},
				},
			},
		},
		Behaviors: map[string]any{
			"showing": map[string]any{
				"shows the list": map[string]any{
					"given": map[string]any{"taskStore.value": []any{"Buy milk"}},
					"when":  "",
					"then":  "homePage.homeContent should be defaultState",
				},
			},
			"toggling": map[string]any{
				"toggling a row toggles its task": map[string]any{
					"given": map[string]any{"taskStore.value": []any{"Buy milk"}},
					"when":  "taskCheckbox.first.taskToggled",
					"then":  "taskStore.value.first should be \"Bought milk\"",
				},
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
