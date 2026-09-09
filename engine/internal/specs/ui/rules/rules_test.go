package uirules

import (
	"testing"

	"github.com/pietroid/metacode/engine/internal/core/model"
	"github.com/pietroid/metacode/engine/internal/specs/ui/catalog"
)

func TestValidateUnknownProp(t *testing.T) {
	comp := model.UIComponent{
		Name: "homePage",
		Kind: "text",
		Props: map[string]any{
			"unknownProp": "value",
		},
	}
	errs := Validate([]model.UIComponent{comp}, catalog.Default())
	if len(errs) != 1 {
		t.Fatalf("expected 1 error, got %d: %v", len(errs), errs)
	}
}

func TestValidateCustomWidgetIgnored(t *testing.T) {
	comp := model.UIComponent{
		Name: "incrementButton",
		Kind: "custom",
	}
	errs := Validate([]model.UIComponent{comp}, catalog.Default())
	if len(errs) != 0 {
		t.Fatalf("expected no errors for custom widget, got %v", errs)
	}
}

func TestValidateRejectsAnUnqualifiedIcon(t *testing.T) {
	comp := model.UIComponent{Name: "addButton", Kind: "icon", Props: map[string]any{"icon": "add"}}
	errs := Validate([]model.UIComponent{comp}, catalog.Default())
	if len(errs) != 1 {
		t.Fatalf("expected 1 error, got %v", errs)
	}
}

func TestValidateRejectsAnUnknownIcon(t *testing.T) {
	comp := model.UIComponent{Name: "addButton", Kind: "icon", Props: map[string]any{"icon": "icons.nope"}}
	errs := Validate([]model.UIComponent{comp}, catalog.Default())
	if len(errs) != 1 {
		t.Fatalf("expected 1 error, got %v", errs)
	}
}

func TestValidateAcceptsAKnownIcon(t *testing.T) {
	comp := model.UIComponent{Name: "addButton", Kind: "icon", Props: map[string]any{"icon": "icons.add"}}
	if errs := Validate([]model.UIComponent{comp}, catalog.Default()); len(errs) != 0 {
		t.Fatalf("expected no errors, got %v", errs)
	}
}

func TestValidateRejectsAHalfDeclaredList(t *testing.T) {
	comp := model.UIComponent{Name: "taskList", Kind: "listView", Props: map[string]any{"items": "visibleTasks"}}
	if errs := Validate([]model.UIComponent{comp}, catalog.Default()); len(errs) != 1 {
		t.Fatalf("expected 1 error for items without item, got %v", errs)
	}
}

func TestValidateRejectsAListThatIsBothStaticAndDynamic(t *testing.T) {
	comp := model.UIComponent{Name: "taskList", Kind: "listView", Props: map[string]any{
		"items": "visibleTasks", "item": "taskTile", "children": []any{},
	}}
	if errs := Validate([]model.UIComponent{comp}, catalog.Default()); len(errs) != 1 {
		t.Fatalf("expected 1 error for both forms, got %v", errs)
	}
}

func TestBuildReadsANestedWidgetAsContent(t *testing.T) {
	raw := map[string]any{
		"widgets": map[string]any{
			"taskArea": map[string]any{
				"expanded": map[string]any{
					"listView": map[string]any{"items": "tasks", "item": "taskTile"},
				},
			},
		},
	}
	symbols := model.NewSymbolTable()
	if err := RegisterWidgets(raw, &symbols); err != nil {
		t.Fatal(err)
	}
	comps, err := Build(raw, symbols)
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if len(comps) != 1 || len(comps[0].Children) != 1 {
		t.Fatalf("expected one child under expanded, got %+v", comps)
	}
	if kind := comps[0].Children[0].Kind; kind != "listView" {
		t.Errorf("expected the listView as content, got kind %q", kind)
	}
	if _, ok := comps[0].Props["listView"]; ok {
		t.Error("the nested widget must not stay a prop")
	}
	if errs := Validate(comps, catalog.Default()); len(errs) != 0 {
		t.Errorf("expected no validation errors, got %v", errs)
	}
}
