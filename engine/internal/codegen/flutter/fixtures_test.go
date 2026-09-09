package flutter

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/build"
	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/core/spec"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func counterAppFullIR() *model.App {
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

func setupGeneratedFiles(t *testing.T, app *model.App) string {
	t.Helper()
	dir := t.TempDir()
	if err := GenerateAll(app, dir); err != nil {
		t.Fatalf("generate all: %v", err)
	}
	return dir
}
